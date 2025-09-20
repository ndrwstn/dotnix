# users/austin/ghostty.nix
{ ... }:
{
  programs.ghostty = {
    enable = true;
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
