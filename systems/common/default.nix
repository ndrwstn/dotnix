# Common configuration shared between all machines

{ config, pkgs, lib, ... }:

{
  imports = [ ./users.nix ];

  # Common system packages
  environment.systemPackages = with pkgs; [
    nh
    vim
    wget
    zsh
  ];

  # Allow unfree packages globally
  nixpkgs.config.allowUnfree = true;
}
