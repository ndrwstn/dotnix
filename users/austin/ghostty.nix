# users/austin/ghostty.nix
{ config, pkgs, lib, unstable, osConfig ? { }, ... }:
let
  windowManagers = osConfig._astn.machine.windowManagers or [ ];
  hasHyprland = builtins.elem "hyprland" windowManagers;
in
{
  programs.ghostty = {
    enable = true;

    # Only install package on NixOS, use unstable version
    package = lib.mkMerge [
      (lib.mkIf (!pkgs.stdenv.isDarwin) unstable.ghostty)
      (lib.mkIf (pkgs.stdenv.isDarwin) null)
    ];

    settings = {
      # Enable CSI u protocol support for modified keys
      term = "xterm-256color";

      # Subtle desktop transparency (NixOS only)
      # This is a NixOS theming feature - opacity doesn't look right on macOS
      # with the default macOS window chrome. If/when macOS gets themed, this
      # can be enabled there too or set to a different value.
      background-opacity = lib.mkIf (!pkgs.stdenv.isDarwin) 0.80;

      # TODO(2026-05-23): This is a hack. Ghostty theming should be
      # handled properly so non-Hyprland machines get a managed fallback
      # instead of simply skipping the matugen-generated config-file.
      config-file = lib.mkIf ((!pkgs.stdenv.isDarwin) && hasHyprland)
        "${config.xdg.configHome}/ghostty/colors.conf";

      # Keybinding configurations
      keybind = [
        # Unbind Ghostty's Ctrl+Enter fullscreen binding to allow it to pass through to nvim
        "ctrl+enter=unbind"

        # Map Shift+Enter to send CSI u sequence that tmux can recognize
        "shift+enter=csi:13;2u"
      ];

      # Additional tmux-friendly settings
      shell-integration = "detect";
      shell-integration-features = "cursor,title";
    };
  };
}
