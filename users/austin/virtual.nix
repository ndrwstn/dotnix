# Minimal Home Manager profile for virtual/server-like systems.
{ config, pkgs, lib, hostName ? "unknown", ... }:
{
  imports = [ ./ssh.nix ];

  home = {
    username = "austin";
    homeDirectory = "/home/austin";
    stateVersion = "24.05";
  };

  xdg.enable = true;

  programs = {
    home-manager.enable = true;

    zsh = {
      enable = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
    };
  };
}
