# users/austin/sops.nix
{ config, lib, pkgs, ... }:

{
  # User-specific sops configuration
  # Packages are now provided at the system level

  # Set up sops directory in user's home
  home.file.".config/sops/age/.keep".text = "";

  # Configure sops for home-manager (NixOS only)
  sops = lib.mkIf (!pkgs.stdenv.isDarwin && (config ? sops)) {
    # Use the user's age key
    age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";

    # Default sops format
    defaultSopsFormat = "yaml";
  };
}
