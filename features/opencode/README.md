# OpenCode v2 Proxmox template

The `opencode` machine is a reusable x86_64 NixOS template for a remote
OpenCode v2 server. Proxmox clones receive their hostname and SSH key through
cloud-init and do not need individual flake machine entries.

## Storage model

The image-builder disk is sized from the closure and is labeled `nixos`, then
mounted at `/nix` and `/boot`.
Runtime root is a tmpfs, so unpersisted changes disappear on every boot. Before
making the VM a Proxmox template, attach and format two additional disks:

```bash
mkfs.ext4 -L persist /dev/<persist-disk>
mkfs.ext4 -L projects /dev/<projects-disk>
```

The disks must be attached to the template so every clone receives its own
copy. They provide:

- `/persist` — machine identity, SSH keys, OpenCode configuration, sessions,
  service credentials, and provider state.
- `/projects` — Git repositories and working trees.

The template contains no project data or reusable Git private keys.

## Build and import

Build the image on an x86_64 Linux builder:

```bash
nix build .#nixosConfigurations.opencode.config.system.build.cloudImage
```

Import the resulting raw image into Proxmox, attach and format the two durable
disks, configure the trusted LAN bridge/VLAN, and convert the VM to a template.
This is the one-time template setup. Clone the template for the default server
or for a stronger per-task isolation boundary.

Configure cloud-init on each clone with a unique hostname and Austin's SSH
public key, then start it. The server listens on TCP port `4096` and uses
OpenCode v2 Basic Auth with username `opencode`.

On the VM, print the pairing QR code and credentials with:

```bash
opencode-pair
```

Use the OpenCode v2 desktop pairing flow, or connect the TUI with the paired
server URL. The server's project locations are the directories under
`/projects`.

## Updates and recovery

The template boots the NixOS generation built into the image. It does not fetch
or rebuild the flake at boot. Update a running clone deliberately from the
controller:

```bash
nixos-rebuild switch --flake .#opencode --target-host austin@<clone-host>
```

The NixOS generation remains available across reboots because `/nix` and
`/boot` are durable. A reboot clears the tmpfs root but preserves `/persist`
and `/projects`.

For project damage, reset or delete the Git working tree and reclone it from
the remote. For complete recovery, stop and delete the clone, then create a
new clone from the pristine Proxmox template.
