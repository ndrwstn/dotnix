# users/austin/default.nix
{ config
, pkgs
, unstable
, autopkgs
, mcppkgs
, lib
, hunk
, osConfig ? { }
, hostName ? "unknown"
, nur ? null
, ...
}:
let
  texlivePackage = import ./texlive.nix { inherit pkgs; };
in
lib.mkMerge [
  #####################
  #####  COMMON   #####
  #####################
  {
    home = {
      username = "austin";
      homeDirectory =
        if pkgs.stdenv.isDarwin
        then "/Users/austin"
        else "/home/austin";
      # Basic configuration
      stateVersion = "24.05";
    };

    # Enable XDG
    xdg = {
      enable = true;
      configHome = "${config.home.homeDirectory}/.config";
      cacheHome = "${config.home.homeDirectory}/.cache";
      dataHome = "${config.home.homeDirectory}/.local/share";
      stateHome = "${config.home.homeDirectory}/.local/state";
    };

    # latexmk configuration in XDG location - add custom extensions to clean
    xdg.configFile."latexmk/latexmkrc".text = ''
      push @generated_exts, "toa";
    '';

    programs = {
      home-manager.enable = true;

      # Shell configuration
      zsh = {
        enable = true;
        autosuggestion.enable = true;
        syntaxHighlighting.enable = true;
        # Lock in legacy dotDir behavior (home directory) to match stateVersion < 26.05
        dotDir = config.home.homeDirectory;
        sessionVariables = {
          TEXMFHOME = "${config.xdg.configHome}/texlive/texmf";
        };
      };

      oh-my-posh = {
        enable = true;
      };

      # Bat configuration
      bat = {
        enable = true;
      };

      # Direnv configuration
      direnv = {
        enable = true;
        enableZshIntegration = true;
        nix-direnv.enable = true;
      };

      # Eza configuration
      eza = {
        enable = true;
        enableZshIntegration = true;
        colors = "auto";
        git = true;
      };

      # fd
      fd = {
        enable = true;
        ignores = [ ".git/" ];
      };

      # Fzf configuration
      fzf = {
        enable = true;
        enableZshIntegration = true;
        tmux.enableShellIntegration = true;
        defaultOptions = [
          "--height 50%"
          "--border"
        ];
      };

      # irssi (irc client)
      irssi = {
        enable = true;
        extraConfig = ''
          settings = {
            core = {
              settings_autosave = "yes";
              settings_dir = "~/.config/irssi";
              #
              real_name = "";
            };
          };
        '';
      };

      # nixvim
      nixvim = import ./nixvim { inherit config pkgs lib texlivePackage unstable; };

      # ripgrep
      ripgrep = {
        enable = true;
      };

      # GitHub CLI configuration
      gh = {
        enable = true;
        settings = {
          telemetry = "disabled";
        };
      };

      # pay-respects (replacement for thefuck)
      pay-respects = {
        enable = true;
        enableZshIntegration = true;
      };

      # Note: Tmux configuration moved to tmux.nix

      # Zoxide configuration
      zoxide = {
        enable = true;
        enableZshIntegration = true;
        options = [
          "--cmd cd"
        ];
      };

      # Firefox with Multi-Account Containers
      firefox = lib.mkIf (nur != null) {
        enable = true;

        # Configure container settings
        profiles.default = {
          extensions.packages = with nur.repos.rycee.firefox-addons; [
            multi-account-containers
          ];

          settings = {
            # Enable Multi-Account Containers
            "privacy.userContext.enabled" = true;
            "privacy.userContext.ui.enabled" = true;
          };

          # Define containers declaratively
          containers = {
            "impetuous" = {
              id = 1;
              name = "Impetuous";
              color = "orange";
              icon = "circle";
            };
          };
        };
      };
    };

    home.activation.ensureLuaLatexFormat =
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        set -u

        state_dir="${config.xdg.stateHome}/texlive"
        marker_file="$state_dir/lualatex-fmt.source"
        log_file="$state_dir/lualatex-fmtutil.log"
        current_marker="${texlivePackage}"
        kpsewhich_bin="${texlivePackage}/bin/kpsewhich"
        fmtutil_bin="${texlivePackage}/bin/fmtutil"

        mkdir -p "$state_dir"

        texmfvar="$($kpsewhich_bin -var-value=TEXMFVAR 2>/dev/null || true)"
        fmt_path=""
        if [ -n "$texmfvar" ]; then
          fmt_path="$texmfvar/web2c/luahbtex/lualatex.fmt"
        fi

        rebuild_needed=0
        if [ ! -f "$marker_file" ]; then
          rebuild_needed=1
        elif [ "$(cat "$marker_file")" != "$current_marker" ]; then
          rebuild_needed=1
        elif [ -z "$fmt_path" ] || [ ! -f "$fmt_path" ]; then
          rebuild_needed=1
        fi

        if [ "$rebuild_needed" -eq 1 ]; then
          if "$fmtutil_bin" --user --byfmt lualatex >"$log_file" 2>&1; then
            texmfvar="$($kpsewhich_bin -var-value=TEXMFVAR 2>/dev/null || true)"
            fmt_path=""
            if [ -n "$texmfvar" ]; then
              fmt_path="$texmfvar/web2c/luahbtex/lualatex.fmt"
            fi
            if [ -n "$fmt_path" ] && [ -f "$fmt_path" ]; then
              printf '%s\n' "$current_marker" > "$marker_file"
              echo "Creating lualatex.fmt ... success."
            else
              echo "Creating lualatex.fmt ... failed (see $log_file)."
            fi
          else
            echo "Creating lualatex.fmt ... failed (see $log_file)."
          fi
        else
          echo "Creating lualatex.fmt ... already present."
        fi
      '';

    # Common packages across all systems
    home.packages = with pkgs; [
      act
      actionlint
      age
      # ansible
      (aspellWithDicts (dicts: with dicts; [ en en-computers en-science la ]))
      bats
      btop
      cachix
      chafa
      clippy
      # cloudflared
      csvkit
      csvlens
      curlie
      deadnix
      eslint
      eza
      # ffmpeg_7
      fd
      ffmpegthumbnailer
      figlet
      firefox
      fluxcd
      # gcc
      gitleaks
      gitlint
      glow
      golangci-lint
      gopls
      # go-task
      hyperfine
      jq
      jqp
      k9s
      kubeconform
      kubectl
      kubernetes-helm
      kubeval
      kustomize
      lazygit
      lolcat
      lua-language-server
      marksman
      moreutils
      mypy
      nil
      nix-diff
      nix-prefetch-scripts
      nix-search-cli
      nix-tree
      nix-update
      nixpkgs-fmt
      nmap
      # NOTE: 2026-06-02 — removed explicit nodejs_22 pin during 26.05 upgrade;
      # the 26.05 default is Node 24 (nodejs). Re-add nodejs_22 if needed for
      # local projects that require Node 22 specifically. This line can be
      # removed entirely once all projects are verified on Node 24.
      # nodejs_22
      prettier
      nvd
      ocrmypdf
      pandoc
      pluto
      poppler-utils
      postgresql
      # printrun
      python3
      python313Packages.markitdown
      pyright
      # rsync
      qpdf
      rage
      yazi
      ruff
      rust-analyzer
      rustfmt
      shellcheck
      shfmt
      ssh-to-age
      sqlfluff
      sqls
      statix
      stylua
      tesseract5
      imagemagick
      ghostscript
      (mermaid-cli.override { chromium = pkgs.ungoogled-chromium; }) # Provides mmdc command for diagram rendering
      # stern
      talosctl
      taplo
      # termpdfpy # terminal pdf viewer
      tdf
      pay-respects
      tlrc
      tree-sitter
      typescript-language-server
      typos
      uv
      # ungoogled-chromium
      watch
      watchexec
      # yed
      yamllint
      yq
      yt-dlp


      ## unstable
      # unstable.librewolf # moved to stable nixpkgs
      pkgs.librewolf
      unstable.tea
      unstable.zmk-studio


      ## overlays
      autopkgs.agent-browser
      autopkgs.gcs
      # autopkgs.marker
      autopkgs.mekhq
      autopkgs.opencode
      autopkgs.opencode-desktop
      # autopkgs.surya
      ## mcppkgs
      mcppkgs.playwright-mcp


      ## fonts
      nerd-fonts.inconsolata


      ## defined variables
      texlivePackage
    ] ++ lib.optional (builtins.hasAttr pkgs.stdenv.hostPlatform.system hunk.packages)
      hunk.packages.${pkgs.stdenv.hostPlatform.system}.hunk;
  }

  # Superfile configured around the Vim editing model.
  {
    programs.superfile = {
      enable = true;
      firstUseCheck = false;

      settings = {
        editor = "nvim";
        dir_editor = "nvim";
        auto_check_update = false;
      };

      hotkeys = {
        # Basic actions
        confirm = [ "enter" ];
        quit = [ "ctrl+c" ];
        cd_quit = [ "Q" ];

        # Navigation
        list_up = [ "k" ];
        list_down = [ "j" ];
        page_up = [ "pgup" ];
        page_down = [ "pgdown" ];

        # File panels
        create_new_file_panel = [ "n" ];
        close_file_panel = [ "q" ];
        next_file_panel = [ "tab" ];
        previous_file_panel = [ "shift+tab" ];
        split_file_panel = [ "N" ];
        toggle_file_preview_panel = [ "f" ];
        open_sort_options_menu = [ "o" ];
        toggle_reverse_sort = [ "R" ];

        # Focus manipulation
        focus_on_process_bar = [ "ctrl+p" ];
        focus_on_sidebar = [ "ctrl+s" ];
        focus_on_metadata = [ "ctrl+d" ];

        # File and directory operations
        file_panel_item_create = [ "a" ];
        file_panel_item_rename = [ "r" ];
        copy_items = [ "y" ];
        cut_items = [ "x" ];
        paste_items = [ "p" ];
        delete_items = [ "d" ];
        permanently_delete_items = [ "D" ];

        # Archive operations
        extract_file = [ "ctrl+e" ];
        compress_file = [ "ctrl+a" ];

        # Editor actions
        open_file_with_editor = [ "e" ];
        open_current_directory_with_editor = [ "E" ];

        # Other actions
        pinned_directory = [ "P" ];
        toggle_dot_file = [ "." ];
        change_panel_mode = [ "m" ];
        open_help_menu = [ "?" ];
        open_spf_prompt = [ ">" ];
        open_command_line = [ ":" ];
        open_zoxide = [ "z" ];
        copy_path = [ "Y" ];
        copy_present_working_directory = [ "c" ];
        toggle_footer = [ "ctrl+f" ];

        # Typing mode
        confirm_typing = [ "enter" ];
        cancel_typing = [ "esc" ];

        # Normal and selection modes
        parent_directory = [ "-" ];
        search_bar = [ "/" ];
        file_panel_select_mode_items_select_down = [ "J" ];
        file_panel_select_mode_items_select_up = [ "K" ];
        file_panel_select_all_items = [ "A" ];
      };
    };
  }

  # Import syncthing configuration
  (import ./syncthing.nix { inherit config pkgs lib hostName unstable; })

  # Import Atuin shell history sync configuration
  (import ./atuin.nix { inherit config pkgs lib hostName; })

  # Import SSH configuration
  (import ./ssh.nix { inherit config pkgs lib hostName; })


  # Import Ghostty terminal configuration
  (import ./ghostty.nix { inherit config pkgs lib unstable osConfig; })

  # Import tmux configuration
  (import ./tmux.nix { inherit config pkgs lib; })

  # Import sesh session manager
  (import ./sesh.nix { inherit config pkgs lib; })

  # Import television (tv) fuzzy finder configuration
  (import ./television.nix { inherit config pkgs lib autopkgs; })

  # Import 1Password secret injection configuration
  (import ./1password.nix { inherit config pkgs lib; })

  # Import git configuration
  (import ./git.nix { inherit config pkgs lib; })

  # Import Darwin-specific flakes
  # NOTE: whisper-cpp is installed Darwin-only because Metal acceleration
  # makes it practical on Apple Silicon. Intel Macs (future NixOS machines)
  # will use remote inference via a k8s OpenVINO cluster; CPU-only whisper
  # is too slow on older Intel hardware to be useful.
  (lib.mkIf pkgs.stdenv.isDarwin (import ./darwin { inherit config pkgs lib autopkgs; }))

  # Import NixOS-specific flakes
  (lib.mkIf (!pkgs.stdenv.isDarwin) (import ./nixos { inherit config pkgs unstable lib osConfig; }))
]
# vim: set tabstop=2 softtabstop=2 shiftwidth=2 expandtab
