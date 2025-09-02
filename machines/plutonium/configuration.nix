# machines/plutonium/configuration.nix
{ config, pkgs, ... }:

{
  # Import secrets configuration
  imports = [
    ./secrets.nix
  ];
  # Machine metadata (used by flake.nix, does not affect system configuration)
  _astn.machineSystem = "x86_64-darwin";

  # Increase download-buffer to 1GB
  nix.settings.download-buffer-size = 1000000000;

  # Define hostname
  networking.hostName = "Plutonium";

  # Environment path
  environment = {
    systemPath = [
      "/usr/local/bin"
      "/usr/local/sbin"
    ];
    systemPackages = with pkgs; [
      coreutils
      gnused
    ];
  };

  # Homebrew
  homebrew.brews = [
    "ddcctl"
  ];

  # Set nix-darwin state version
  system.stateVersion = 4;
}

