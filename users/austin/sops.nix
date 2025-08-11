# users/austin/sops.nix
{ config, lib, pkgs, ... }:

{
  # User-specific sops configuration
  home.packages = with pkgs; [
    sops
    age
  ];
  
  # Set up sops directory in user's home
  home.file.".config/sops/age/.keep".text = "";
}