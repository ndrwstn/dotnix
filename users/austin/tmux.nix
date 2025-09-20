# users/austin/tmux.nix
{ pkgs, ... }:
{
  programs.tmux = {
    enable = true;
    terminal = "tmux-256color";
    baseIndex = 1;
    historyLimit = 50000;
    mouse = true;
    plugins = with pkgs.tmuxPlugins; [ vim-tmux-navigator ];

    extraConfig = ''
      # Bind Shift+Enter to send newline (or customize this action)
      bind -n S-Enter send-keys C-m
    '';
  };
}
