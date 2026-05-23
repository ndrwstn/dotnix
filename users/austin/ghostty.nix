# users/austin/ghostty.nix
{ pkgs, lib, unstable, osConfig ? { }, ... }:
let
  windowManagers = osConfig._astn.machine.windowManagers or [
    "gnome"
    "hyprland"
  ];
  hasHyprland = builtins.elem "hyprland" windowManagers;
  enableGhostty = pkgs.stdenv.isDarwin || hasHyprland;
in
{
  programs.ghostty = {
    enable = enableGhostty;

    # Only install package on Hyprland NixOS, use unstable version.
    # Darwin installs Ghostty with Homebrew.
    package = lib.mkMerge [
      (lib.mkIf (!pkgs.stdenv.isDarwin && hasHyprland) unstable.ghostty)
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
