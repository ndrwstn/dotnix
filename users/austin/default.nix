# users/austin/default.nix
{ config
, pkgs
, unstable
, autopkgs
, mcppkgs
, lib
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

      # Git configuration
      git = {
        enable = true;
        settings.user = {
          name = "Andrew Austin";
          email = "austin@impetuo.us";
        };
      };

      # Shell configuration
      zsh = {
        enable = true;
        autosuggestion.enable = true;
        syntaxHighlighting.enable = true;
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
      clippy
      # cloudflared
      csvkit
      csvlens
      curlie
      deadnix
      delta
      eslint
      eza
      # ffmpeg_7
      fd
      figlet
      firefox
      fluxcd
      # gcc
      gh
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
      nodejs_22
      nodePackages.prettier
      nvd
      ocrmypdf
      pandoc
      pluto
      poppler-utils
      # printrun
      python3
      pyright
      # rsync
      qpdf
      rage
      ranger
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
      nodePackages.mermaid-cli # Provides mmdc command for diagram rendering
      # stern
      talosctl
      taplo
      termpdfpy # terminal pdf viewer
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
      unstable.tea


      ## overlays
      claude-code
      autopkgs.agent-browser
      autopkgs.gcs
      # autopkgs.marker
      autopkgs.opencode
      autopkgs.opencode-desktop
      # autopkgs.surya

      ## mcppkgs
      mcppkgs.playwright-mcp


      ## fonts
      nerd-fonts.inconsolata


      ## defined variables
      texlivePackage
    ];
  }

  # Import syncthing configuration
  (import ./syncthing.nix { inherit config pkgs lib hostName unstable; })

  # Import Atuin shell history sync configuration
  (import ./atuin.nix { inherit config pkgs lib hostName; })

  # Import SSH configuration
  (import ./ssh.nix { inherit config pkgs lib hostName; })


  # Import Ghostty terminal configuration
  (import ./ghostty.nix { inherit config pkgs lib unstable; })

  # Import tmux configuration
  (import ./tmux.nix { inherit config pkgs lib; })

  # Import Darwin-specific flakes
  (lib.mkIf pkgs.stdenv.isDarwin (import ./darwin { inherit config pkgs lib autopkgs; }))

  # Import NixOS-specific flakes
  (lib.mkIf (!pkgs.stdenv.isDarwin) (import ./nixos { inherit config pkgs unstable lib; }))
]
# vim: set tabstop=2 softtabstop=2 shiftwidth=2 expandtab
