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
      # --- CORE FIXES ---
      # Eliminate ESC delay (interferes with nvim/opencode keyboard input)
      set -sg escape-time 10

      # Enable kitty graphics protocol passthrough
      set -g allow-passthrough on

      # Load wallpaper-driven colors if present
      if-shell "test -f ${config.xdg.configHome}/tmux/tmux-colors.conf" \
        "source-file ${config.xdg.configHome}/tmux/tmux-colors.conf"

      # --- SPLITS ---
      bind \ split-window -h    # vertical split (pane on right)
      bind - split-window -v    # horizontal split (pane below)

      # --- STATUS BAR ---
      set -g status-position bottom
      set -g status-style "bg=#{@matugen_surface0}"
      set -g status-justify centre
      set -g status-left-length 32
      set -g status-right-length 80
      set -g status-left " #[bold]#S "
      set -g status-right " #[fg=#{@matugen_accent}]#(whoami)@#H#[default] "
      set -g window-status-style "fg=#45475a"
      set -g window-status-current-style "fg=#{@matugen_accent},bold"
      set -g window-status-activity-style "fg=#{@matugen_accent}"
      set -g window-status-format " #I:#W "
      set -g window-status-current-format " #I:#W#{?window_zoomed_flag, 󰊓,} "

      # Toggle status bar (useful for fullscreen nvim focus)
      bind B set -g status

      # --- KEYBINDINGS ---
      # Shift+Enter sends line feed (inserts newline, doesn't submit)
      bind -n S-Enter send-keys C-j
    '';
  };
}
