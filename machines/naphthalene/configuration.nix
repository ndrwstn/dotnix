# machines/naphthalene/configuration.nix
# LXC builder on Proxmox — headless remote builder and build host.
{ config, pkgs, lib, modulesPath, ... }:

let
  inherit (lib) mkDefault;
in
{
  imports = [
    ./secrets.nix
    # LXC-specific virtualization module
    (modulesPath + "/virtualisation/proxmox-lxc.nix")
  ];

  # Machine metadata
  _astn.machineSystem = "x86_64-linux";
  _astn.machineRole = "virtual";

  # ============================================================================
  # LXC-specific configuration
  # ============================================================================
  systemd.suppressedSystemUnits = [
    "dev-mqueue.mount"
    "sys-kernel-debug.mount"
    "sys-fs-fuse-connections.mount"
  ];

  # ============================================================================
  # Networking
  # ============================================================================
  networking.hostName = "naphthalene";

  # ============================================================================
  # System packages
  # ============================================================================
  environment.systemPackages = with pkgs; [
    git
    vim
  ];

  # ============================================================================
  # Home-manager — CLI-only user config for builder duties
  # ============================================================================
  # Override auto-discovered home-manager to skip desktop/GUI user configs.
  home-manager.users.austin = lib.mkForce {
    imports = [
      ../../users/austin/git.nix
      ../../users/austin/ssh.nix
    ];

    home = {
      username = "austin";
      homeDirectory = "/home/austin";
      stateVersion = "24.05";
    };

    xdg.enable = true;
    programs.zsh.enable = true;
  };

  # ============================================================================
  # System state
  # ============================================================================
  system.stateVersion = "26.05";
}
