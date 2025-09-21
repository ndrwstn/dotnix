# users/austin/ghostty.nix
{ config, pkgs, lib, unstable, ... }:
{
  programs.ghostty = {
    enable = true;

    # Only install package on NixOS, use unstable version
    package = lib.mkIf (!pkgs.stdenv.isDarwin) unstable.ghostty;

    settings = {
      # Enable CSI u protocol support for modified keys
      term = "xterm-256color";

      # Map Shift+Enter to send CSI u sequence that tmux can recognize
      keybind = "shift+enter=csi:13;2u";

      # Additional tmux-friendly settings
      shell-integration = "detect";
      shell-integration-features = "cursor,title";
    };
  };
}
