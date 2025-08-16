# users/austin/sops.nix
{ config, lib, pkgs, ... }:

{
  # User-specific sops configuration
  # Packages are now provided at the system level

  # Set up sops directory in user's home
  home.file.".config/sops/age/.keep".text = "";
}
