# machines/plutonium/configuration.nix
{ config, pkgs, ... }:

{
  # Define hostname
  networking.hostName = "Plutonium";
  
  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Environment path
  environment.systemPath = [
    "/opt/homebrew/bin"
    "/opt/homebrew/sbin"
  ];
  
  # System packages
  environment.systemPackages = with pkgs; [
    coreutils
    gnused
  ];
  
  # Set nix-darwin state version
  system.stateVersion = 4;
}