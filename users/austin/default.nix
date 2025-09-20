# users/austin/default.nix
{ config
, pkgs
, unstable
, autopkgs
, lib
, hostName ? "unknown"
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

    programs = {
      home-manager.enable = true;

      # Git configuration
      git = {
        enable = true;
        userName = "Andrew Austin";
        userEmail = "austin@impetuo.us";
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
      nixvim = import ./nixvim { inherit config pkgs lib texlivePackage; };

      # oh-my-posh
      oh-my-posh = {
        enable = true;
      };

      # ripgrep
      ripgrep = {
        enable = true;
      };

      # thefuck
      thefuck = {
        enable = true;
        # TODO - 'esc' alias
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
    };

    # Common packages across all systems
    home.packages = with pkgs; [
      act # Run GitHub Actions locally
      actionlint # GitHub Actions linter
      age # Modern encryption tool
      # ansible
      (aspellWithDicts (dicts: with dicts; [ en en-computers en-science la ]))
      bats # Bash testing framework
      clippy # Rust linter
      # cloudflared
      curlie # Modern curl alternative
      deadnix # Dead Nix code scanner
      # docker
      eslint # JavaScript/TypeScript linter
      eza
      # ffmpeg_7
      fd
      # firefox
      fluxcd
      # gcc
      gh # GitHub CLI
      gitleaks # Git secrets scanner
      gitlint # Git commit message linter

      golangci-lint # Go linter
      gopls # Go language server
      # go-task
      hyperfine # Command-line benchmarking
      jq # JSON processor
      k9s
      kubeconform
      kubectl
      kubernetes-helm
      kubeval # Kubernetes YAML validator
      kustomize

      lazygit
      lua-language-server
      marksman
      moreutils # Additional Unix utilities
      mypy # Python type checker
      nil
      nix-diff # Nix derivation diff tool
      nix-prefetch-scripts
      nix-tree # Nix dependency tree viewer
      nixpkgs-fmt
      # nmap
      nodejs_22
      nodePackages.prettier
      nvd # Nix version diff tool
      pluto # Kubernetes deprecated API detector
      # printrun
      # python3
      pyright
      # rsync
      qpdf
      rage # Rust implementation of age encryption
      ruff # Python linter and formatter
      rust-analyzer # Rust language server
      rustfmt # Rust formatter
      shellcheck # Shell script linter
      shfmt
      ssh-to-age # Convert SSH keys to age keys
      sqlfluff
      sqls
      statix # Nix linter
      stylua
      # stern
      talosctl
      taplo
      thefuck
      tlrc
      tree-sitter
      typescript-language-server # TypeScript language server
      typos # Source code spell checker
      # ungoogled-chromium
      watch
      watchexec # Execute commands on file changes
      # yed
      yamllint # YAML linter
      yq # YAML processor
      # yt-dlp
      ## overlays
      autopkgs.gcs
      autopkgs.opencode
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
  (import ./ghostty.nix { inherit config pkgs lib; })

  # Import tmux configuration
  (import ./tmux.nix { inherit config pkgs lib; })

  # Import Darwin-specific flakes
  (lib.mkIf pkgs.stdenv.isDarwin (import ./darwin { inherit config pkgs lib; }))

  # Import NixOS-specific flakes
  (lib.mkIf (!pkgs.stdenv.isDarwin) (import ./nixos { inherit config pkgs lib; }))
]
# vim: set tabstop=2 softtabstop=2 shiftwidth=2 expandtab

