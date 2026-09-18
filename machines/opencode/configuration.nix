# Reusable OpenCode v2 Proxmox template.
{ config, lib, modulesPath, opencode, pkgs, ... }:

let
  inherit (lib) mkDefault mkForce;

  # The NixOS disk-image builder runs its copy/mkfs phase inside QEMU. Enable
  # parallel execution for that VM and cap it so it does not consume every
  # core on the shared remote builder.
  parallelImageBuildOverlay = final: prev: {
    # make-disk-image.nix invokes cptofs inside the image-builder VM.  cptofs
    # uses LKL to walk the staging tree, which is exposed to that VM through
    # virtiofs.  On the remote builder this produces thousands of silent
    # `Invalid argument` readdir failures and can yield a truncated image.
    # Replace only cptofs with mkfs.ext4's native directory-population mode;
    # loop devices are not available inside the image-builder VM.
    lkl = prev.symlinkJoin {
      name = "lkl-with-safe-cptofs";
      paths = [ prev.lkl.out ];
      postBuild = ''
          rm "$out/bin/cptofs"
        install -m 755 /dev/stdin "$out/bin/cptofs" <<'EOF'
          #!${final.runtimeShell}
          set -euo pipefail

          partition=""
          image=""
          sources=()

          while (($#)); do
            case "$1" in
              -p)
                shift
                ;;
              -P)
                partition="$2"
                shift 2
                ;;
              -t)
                shift 2
                ;;
              -i)
                image="$2"
                shift 2
                ;;
              --)
                shift
                sources+=("$@")
                break
                ;;
              *)
                sources+=("$1")
                shift
                ;;
            esac
          done

          last=$((''${#sources[@]} - 1))
          destination="''${sources[$last]}"
          unset "sources[$last]"
          test -n "$image"
          test -n "$destination"

        if [ "$partition" != 1 ]; then
          echo "safe cptofs only supports partition 1" >&2
          exit 2
        fi

        staging=$(mktemp -d)
        filesystem=$(mktemp "$image.fs.XXXXXX")
        cleanup() {
          rm -rf "$staging"
          rm -f "$filesystem"
        }
        trap cleanup EXIT

        for source in "''${sources[@]}"; do
          cp -a "$source" "$staging/"
        done
        # e2fsdroid, used by mkfs.ext4 -d, normalizes the source tree while
        # populating the filesystem.  cp -a preserved the Nix store's
        # read-only modes, so make the temporary copy writable first.
        chmod -R u+w "$staging"

        offset=$((1024 * 1024))
        uuid=$(blkid -p -o value -s UUID --offset "$offset" "$image")
        label=$(blkid -p -o value -s LABEL --offset "$offset" "$image")
        test -n "$uuid"
        test -n "$label"
        blocks=$(( ($(stat -c %s "$image") - offset) / 4096 ))
        truncate -s "$((blocks * 4096))" "$filesystem"
        mkfs.ext4 -b 4096 -F -L "$label" -U "$uuid" -d "$staging" \
          "$filesystem" "$blocks"
        dd if="$filesystem" of="$image" bs=4096 \
          seek="$((offset / 4096))" conv=notrunc status=none
        sync
        EOF
      '';
    };

    vmTools = prev.vmTools // {
      runInLinuxVM = drv:
        prev.vmTools.runInLinuxVM (
          drv.overrideAttrs (_: {
            enableParallelBuilding = true;
            env.NIX_BUILD_CORES = "8";
          })
        );
    };
  };
in
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    (modulesPath + "/virtualisation/proxmox-image.nix")
  ];

  nixpkgs.overlays = [ parallelImageBuildOverlay ];

  # Clones receive their final hostname from Proxmox cloud-init.
  networking.hostName = mkDefault "opencode";

  proxmox.qemuConf = {
    bios = "seabios";
    cores = 2;
    memory = 4096;
    name = "NixOS-OPENCODE-${config.system.nixos.label}";
    net0 = "virtio,bridge=vmbr0,tag=50";
  };

  image.baseName = "NixOS-OPENCODE-${config.system.nixos.label}";

  proxmox.partitionTableType = "legacy";
  # Avoid cptofs pathologies from copying into a mostly-empty fixed-size
  # filesystem. Proxmox can grow the imported disk at deployment time.
  virtualisation.diskSize = "auto";

  # The image-builder disk is labeled `nixos` and is mounted at /nix at
  # runtime. The root itself is a fresh tmpfs on every boot. Two additional
  # labeled disks are attached before converting the VM into a Proxmox template.
  fileSystems."/" = mkForce {
    device = "none";
    fsType = "tmpfs";
    options = [ "mode=0755" "size=25%" ];
  };

  fileSystems."/nix" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
    neededForBoot = true;
    options = [ "noatime" ];
  };

  # The legacy image keeps /boot on the same durable image disk. Mounting the
  # disk here makes boot generations available while / is a tmpfs.
  fileSystems."/boot" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
    neededForBoot = true;
    options = [ "noatime" ];
  };

  fileSystems."/persist" = {
    device = "/dev/disk/by-label/persist";
    fsType = "ext4";
    neededForBoot = true;
    options = [ "noatime" ];
  };

  fileSystems."/projects" = {
    device = "/dev/disk/by-label/projects";
    fsType = "ext4";
    neededForBoot = true;
    options = [ "noatime" ];
  };

  systemd.tmpfiles.rules = [
    "d /projects 2770 austin projects -"
    "d /persist 0750 root root -"
  ];

  users.groups.projects = { };
  users.users.austin.extraGroups = [ "projects" ];

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
      AllowUsers = [ "austin" ];
    };
  };

  # v2 managed-service mode persists its generated Basic Auth password in the
  # service user's OpenCode config. This helper prints the pairing QR code as
  # that user, without putting the password in the Nix configuration.
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "opencode-pair" ''
      exec ${pkgs.sudo}/bin/sudo -u opencode ${opencode}/bin/opencode pair "$@"
    '')
  ];

  # Keep the virtual profile desktop-free while providing a usable SSH shell.
  home-manager.users.austin = mkForce {
    home = {
      username = "austin";
      homeDirectory = "/home/austin";
      stateVersion = "24.05";
    };

    xdg.enable = true;
    programs = {
      home-manager.enable = true;
      zsh.enable = true;
      ssh = {
        enable = true;
        enableDefaultConfig = false;
        settings."*" = {
          IdentitiesOnly = "yes";
          StrictHostKeyChecking = "accept-new";
        };
      };
    };
  };

  system.stateVersion = "26.05";
}
