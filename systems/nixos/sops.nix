# systems/nixos/sops.nix
{ config, lib, pkgs, ... }:

{
  # NixOS-specific sops configuration
  sops = {
    # Use the default age key location
    age.keyFile = "/var/lib/sops-nix/key.txt";
    
    # Generate an age key if one doesn't exist
    age.generateKey = true;
    
    # Install the sops-nix packages
    packages = with pkgs; [
      sops
      age
    ];
  };
  
  # Add sops-related packages to the system
  environment.systemPackages = with pkgs; [
    sops
    age
  ];
}