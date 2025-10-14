# users/austin/default.nix
{ config
, pkgs
, unstable
, autopkgs
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

    # Common packages across all systems
    home.packages = with pkgs; [
      act
      actionlint
      age
      # ansible
      (aspellWithDicts (dicts: with dicts; [ en en-computers en-science la ]))
      bats
      clippy
      # cloudflared
      curlie
      deadnix
      # docker
      eslint
      eza
      # ffmpeg_7
      fd
      firefox
      fluxcd
      # gcc
      gh
      gitleaks
      gitlint
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
      lua-language-server
      marksman
      moreutils
      mypy
      nil
      nix-diff
      nix-prefetch-scripts
      nix-tree
      nix-update
      nixpkgs-fmt
      # nmap
      nodejs_22
      nodePackages.prettier
      nvd
      pluto
      # printrun
      # python3
      pyright
      # rsync
      qpdf
      rage
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
      # stern
      talosctl
      taplo
      thefuck
      tlrc
      tree-sitter
      typescript-language-server
      typos
      # ungoogled-chromium
      watch
      watchexec
      # yed
      yamllint
      yq
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
  (import ./ghostty.nix { inherit config pkgs lib unstable; })

  # Import tmux configuration
  (import ./tmux.nix { inherit config pkgs lib; })

  # Import Darwin-specific flakes
  (lib.mkIf pkgs.stdenv.isDarwin (import ./darwin { inherit config pkgs lib; }))

  # Import NixOS-specific flakes
  (lib.mkIf (!pkgs.stdenv.isDarwin) (import ./nixos { inherit config pkgs unstable lib; }))
]
# vim: set tabstop=2 softtabstop=2 shiftwidth=2 expandtab

