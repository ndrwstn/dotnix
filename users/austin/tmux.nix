# users/austin/tmux.nix
{ pkgs, config, lib, ... }:
let
  defaultTmuxpWindows = ''
    - window_name: opencode
      focus: true
      panes:
        - shell_command:
            - opencode

    - window_name: lazygit
      panes:
        - shell_command:
            - lazygit

    - window_name: shell
      panes:
        - shell_command:
            - zsh
  '';

  mkTmuxpWorkspace = { sessionName, startDirectory, windows ? defaultTmuxpWindows }: {
    text = ''
      session_name: ${sessionName}
      start_directory: ${startDirectory}

      windows:
      ${windows}
    '';
  };

  workspaceBase = "${config.home.homeDirectory}/Documents";

  tmuxpWorkspaces = {
    "nix.yaml" = {
      sessionName = "NIX";
      startDirectory = "${workspaceBase}/90__CONFIG/NIX";
    };

    "mckean.yaml" = {
      sessionName = "MCKEAN";
      startDirectory = "${workspaceBase}/90__CONFIG/MCKEAN";
    };

    "uslegal.yaml" = {
      sessionName = "USLEGAL";
      startDirectory = "${workspaceBase}/03__PROGRAMMING/USLEGAL";
    };

    "impetuous.yaml" = {
      sessionName = "IMPETUOUS";
      startDirectory = "${workspaceBase}/04__NETWORKING/01__KHC-PROD__IMPETUOUS";
      windows = ''
        - window_name: opencode
          focus: true
          panes:
            - shell_command:
                - opencode

        - window_name: lazygit
          panes:
            - shell_command:
                - lazygit

        - window_name: shell
          panes:
            - shell_command:
                - zsh

        - window_name: k9s
          panes:
            - shell_command:
                - k9s

        - window_name: talosctl
          panes:
            - shell_command:
                - talosctl dashboard -n 10.1.50.51,10.1.50.52,10.1.50.53 -e 10.1.50.50
      '';
    };

    "opencode-app.yaml" = {
      sessionName = "OPENCODE-APP";
      startDirectory = "${workspaceBase}/03__PROGRAMMING/OPENCODE-APP";
    };

    "opencode.yaml" = {
      sessionName = "OPENCODE";
      startDirectory = "${workspaceBase}/90__CONFIG/OPENCODE";
    };

    "television.yaml" = {
      sessionName = "TELEVISION";
      startDirectory = "${workspaceBase}/90__CONFIG/TELEVISION";
    };

    "zmk.yaml" = {
      sessionName = "ZMK";
      startDirectory = "${workspaceBase}/90__CONFIG/ZMK";
    };

    "dropzone-actions.yaml" = {
      sessionName = "DROPZONE-ACTIONS";
      startDirectory = "${workspaceBase}/03__PROGRAMMING/DROPZONE-ACTIONS";
    };

    "nixautopkgs.yaml" = {
      sessionName = "NIXAUTOPKGS";
      startDirectory = "${workspaceBase}/03__PROGRAMMING/NIXAUTOPKGS";
    };

    "tdf-app.yaml" = {
      sessionName = "TDF-APP";
      startDirectory = "${workspaceBase}/03__PROGRAMMING/TDF-APP";
    };

    "avery-latex.yaml" = {
      sessionName = "AVERY-LATEX";
      startDirectory = "${workspaceBase}/03__PROGRAMMING/AVERY-LATEX";
    };

    "orcaslicer.yaml" = {
      sessionName = "ORCASLICER";
      startDirectory = "${workspaceBase}/90__CONFIG/ORCASLICER";
      windows = ''
        - window_name: opencode
          focus: true
          panes:
            - shell_command:
                - opencode

        - window_name: lazygit
          panes:
            - shell_command:
                - lazygit

        - window_name: tools
          layout: even-vertical
          panes:
            - shell_command:
                - yazi
            - shell_command:
                - zsh
      '';
    };

    "sovol-sv06.yaml" = {
      sessionName = "SOVOL-SV06";
      startDirectory = "${workspaceBase}/90__CONFIG/SOVOL_SV06";
      windows = ''
        - window_name: opencode
          focus: true
          panes:
            - shell_command:
                - opencode

        - window_name: lazygit
          panes:
            - shell_command:
                - lazygit

        - window_name: tools
          layout: even-vertical
          panes:
            - shell_command:
                - yazi
            - shell_command:
                - zsh
      '';
    };
  };
in
{
  xdg.configFile = lib.mapAttrs'
    (fileName: workspace:
      lib.nameValuePair "tmuxp/${fileName}" (mkTmuxpWorkspace workspace))
    tmuxpWorkspaces;

  programs.tmux = {
    enable = true;
    tmuxp.enable = true;
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

      # Stay inside tmux when the current session is destroyed
      set -g detach-on-destroy off

      # Tell tmux that Ghostty supports true color for both the current
      # xterm-256color TERM and Ghostty's native xterm-ghostty TERM.
      set -as terminal-features ',xterm-256color:RGB'
      set -as terminal-features ',xterm-ghostty:RGB'

      # Forward modified keys like Ctrl+Enter using CSI-u when supported.
      set -s extended-keys on
      set -s extended-keys-format csi-u

      # Report descriptive tmux titles to the outer terminal (e.g. Ghostty)
      set -g set-titles on
      set -g set-titles-string "tmux / #{session_name} / #{window_name}"

      # --- SPLITS ---
      bind \\ split-window -h    # vertical split (pane on right)
      bind - split-window -v    # horizontal split (pane below)

      # --- STATUS BAR ---
      set -g status-position bottom
      set -g status-style "bg=default"
      set -g status-justify centre
      set -g status-left-length 32
      set -g status-right-length 80
      set -g status-left " #[bold]#S "
      set -g status-right " #(whoami)@#H "
      set -g window-status-current-style "bold"
      set -g window-status-activity-style "none"
      set -g window-status-style "fg=#45475a"
      set -g window-status-format " #I:#W "
      set -g window-status-current-format " #I:#W#{?window_zoomed_flag, 󰊓,} "

      # Toggle status bar (useful for fullscreen nvim focus)
      bind B set -g status

      # Sesh helpers
      bind-key W run-shell "sesh window \"$(sesh window | fzf --tmux 60%,50% --prompt '🪟  ')\""
      bind -N "last-session (via sesh)" L run-shell "sesh last"

      # --- KEYBINDINGS ---
      # Shift+Enter sends line feed (inserts newline, doesn't submit)
      bind -n S-Enter send-keys C-j
    '';
  };
}
