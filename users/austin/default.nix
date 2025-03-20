# users/austin/default.nix
{
  config,
  pkgs,
  unstable,
  lib,
  ...
}:
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
        ignores = [".git/"];
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

      # neovim
      neovim = {
        enable = true;
      };

      nvf = {
        enable = true;
        settings = import ./nvf {inherit config pkgs;};
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

      # Tmux configuration
      tmux = {
        enable = true;
        terminal = "tmux-256color";
        baseIndex = 1;
        historyLimit = 50000;
        mouse = true;
      };

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
      _1password-cli
      # _1password-gui
      # age
      # ansible
      # cloudflared
      # docker
      eza
      # ffmpeg_7
      fd
      # firefox
      # fluxcd
      # gcc
      # go-task
      # jq
      # kubeconform
      # kubectl
      # kubernetes-helm
      # kustomize
      # moreutils
      # nmap
      # nodejs_22
      # printrun
      # python3
      # rsync
      # sops
      # stern
      # talosctl
      thefuck
      tlrc
      tree-sitter
      # ungoogled-chromium
      # yed
      # yq
      # yt-dlp
      # zathura
      ## import
      (import ./texlive.nix {inherit pkgs;})
      ## fonts
      nerd-fonts.inconsolata
    ];
  }

  # Import Darwin-specific flakes
  (lib.mkIf pkgs.stdenv.isDarwin (import ./darwin {inherit config pkgs lib;}))

  # Import NixOS-specific flakes
  (lib.mkIf (!pkgs.stdenv.isDarwin) (import ./nixos {inherit config pkgs unstable lib;}))
]
# vim: set tabstop=2 softtabstop=2 shiftwidth=2 expandtab

