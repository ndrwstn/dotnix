# users/austin/tmux.nix
{ pkgs, config, ... }:
{
  programs.tmux = {
    enable = true;
    terminal = "tmux-256color";
    baseIndex = 1;
    historyLimit = 50000;
    mouse = true;
    plugins = with pkgs.tmuxPlugins; [ vim-tmux-navigator ];

    extraConfig = ''
      # Load wallpaper-driven colors if present
      if-shell "test -f ${config.xdg.configHome}/tmux/tmux-colors.conf" "source-file ${config.xdg.configHome}/tmux/tmux-colors.conf"

      set -g status-left-length 32
      set -g status-right-length 80
      set -g status-left " #[bold]#S "
      set -g status-right " #[fg=#{@matugen_accent}]#(whoami)#[default] • %Y-%m-%d %H:%M "
      set -g window-status-format " #I:#W "
      set -g window-status-current-format " #I:#W#{?window_zoomed_flag, 󰊓,} "

      # Bind Shift+Enter to send newline (or customize this action)
      bind -n S-Enter send-keys C-m
    '';
  };
}
