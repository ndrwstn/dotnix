# Reusable OpenCode v2 Proxmox template.
{ config, lib, modulesPath, opencode, pkgs, ... }:

let
  inherit (lib) mkDefault mkForce;

  # The NixOS disk-image builder runs its copy/mkfs phase inside QEMU. Enable
  # parallel execution for that VM and cap it so it does not consume every
  # core on the shared remote builder.
  parallelImageBuildOverlay = final: prev: {
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
