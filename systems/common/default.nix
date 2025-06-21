# systems/common/default.nix

{
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [./users.nix];

  # Common system packages
  environment.systemPackages = with pkgs; [
    jdk17
    nh
    vim
    wget
    zsh
  ];

  # Allow unfree packages globally
  nixpkgs.config.allowUnfree = true;
}
