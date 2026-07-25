# systems/virtual/default.nix
# Minimal headless NixOS profile for virtual/utility machines (LXCs, VMs).
#
# This is an alternative to systems/nixos/default.nix (desktop-oriented)
# for machines that don't need GUI components: remote builders, template
# VMs, appliance containers, etc.
#
# Role annotations (specified via _astn.machineRole in machine configs):
#   "virtual"  → LXC containers, purpose-built VMs (naphthalene)
#   "template" → Clonable disk images (_opencode)
#   "server"   → Future: headless NixOS on bare metal
#   "appliance" → Future: Raspberry Pi / embedded
#   "laptop", "desktop" → Currently use systems/nixos (no change needed)
{ config, pkgs, lib, ... }:

{
  imports = [
    # Shared system components
    ../../systems/common
    # Agenix for secrets management
    ../../systems/nixos/agenix.nix
  ];

  # ============================================================================
  # Nix Settings
  # ============================================================================
  nixpkgs.config.allowUnfree = true;
  nixpkgs.overlays = import ../../overlays;

  # nix-ld support for dynamically linked binaries
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    zlib
    zstd
    stdenv.cc.cc
    curl
    openssl
    attr
    libssh
    bzip2
    libxml2
    acl
    libsodium
    util-linux
    xz
    systemd
    brotli
    libffi
    gmp
  ];

  # ============================================================================
  # SSH Server
  # ============================================================================
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  # ============================================================================
  # Firewall
  # ============================================================================
  networking.firewall = {
    enable = true;
    # SSH is the default; machines open additional ports as needed
    allowedTCPPorts = [ 22 ];
  };

  # ============================================================================
  # System Settings
  # ============================================================================
  time.timeZone = "America/New_York";
  i18n.defaultLocale = "en_US.UTF-8";

  # ============================================================================
  # Users
  # ============================================================================
  users.users.austin = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIq17FR5ZqbN7a1uVVwojvvES/f7mgagiixc6OcZicnG austin@impetuo.us"
    ];
  };

  # Ensure wheel users have passwordless sudo
  security.sudo.wheelNeedsPassword = false;
}
