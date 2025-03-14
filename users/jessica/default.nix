# users/jessica/default.nix
{ config, pkgs, unstable, ... }:

{
  home.username = "jessica";
  home.homeDirectory = if pkgs.stdenv.isDarwin 
    then "/Users/jessica"
    else "/home/jessica";
  
  # Basic configuration
  home.stateVersion = "24.05";
  
  # Enable XDG
  xdg.enable = true;

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # Common packages across all systems
  home.packages = with pkgs; [
    # _1password-gui
    # libreoffice-qt6-fresh
    # teams-for-linux
    # vlc
  ];

}
# vim: set tabstop=2 softtabstop=2 shiftwidth=2 expandtab 
