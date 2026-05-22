# users/austin/sesh.nix
{ config, pkgs, lib, ... }:
{
  programs.sesh = {
    enable = true;
    enableTmuxIntegration = true;
    tmuxKey = "s";
    icons = true;
    enableAlias = false;
    settings = {
      cache = true;
      separator_aware = true;

      sort_order = [
        "tmux"
        "config"
        "zoxide"
      ];

      blacklist = [
        "scratch"
        "tmp"
        "popup"
      ];

      tui = {
        prompt = "⚡  ";
        placeholder = "Pick a session...";
        show_icons = true;
      };

      default_session = {
        preview_command = "eza --all --git --icons --color=always {}";
      };
    };
  };
}
