# machines/plutonium/configuration.nix
{ config, pkgs, ... }:

{
  # Define hostname
  networking.hostName = "Plutonium";

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

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

