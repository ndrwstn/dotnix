# systems/darwin/sops.nix
{ config, lib, pkgs, ... }:

{
  # Darwin-specific sops configuration
  
  # Add sops-related packages to the system
  environment.systemPackages = with pkgs; [
    sops
    age
  ];
  
  # Set up the age key directory
  system.activationScripts.postActivation.text = ''
    # Create sops-nix directories
    mkdir -p /var/lib/sops-nix
    chmod 700 /var/lib/sops-nix
  '';
}