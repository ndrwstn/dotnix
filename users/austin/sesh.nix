# users/austin/sesh.nix
{ config, pkgs, lib, ... }:
{
  programs.sesh = {
    enable = true;
    enableTmuxIntegration = true;
    tmuxKey = "s";
    icons = true;
    enableAlias = false;
    settings = { };
  };
}
