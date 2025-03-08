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
      _1password-gui
      age
      ansible
      calibre
      cloudflared
      docker
      eza
      ffmpeg_7
      firefox
      fluxcd
      gcc
      go-task
      jq
      kubeconform
      kubectl
      kubernetes-helm
      kustomize
      moreutils
      neovide
      nmap
      nodejs_22
      printrun
      python3
      rsync
      sops
      stern
      talosctl
      thefuck
      tlrc
      tldr
      tree-sitter
      ungoogled-chromium
      yed
      yq
      yt-dlp
      zathura
      ## unstable
      unstable.ghostty
      ## import
      (import ./texlive.nix {inherit pkgs;})
    ];
  }
  #####################
  #####  DARWIN   #####
  #####################
  (lib.mkIf pkgs.stdenv.isDarwin {
    homebrew = {
      casks = [
        # "1password"
        "appcleaner"
        "balenaetcher"
        "blender"
        "brave-browser"
        # "chromium" # NOTE -- not installed in favor of 'elonston-chromium' (ungoogled version)
        "dbeaver-community"
        "discord"
        "eloston-chromium" # NOTE -- ungoogled version?
        "freecad"
        "gimp"
        "gqrx"
        "inkscape"
        "jdownloader"
        "jordanbaird-ice"
        "keka"
        "kicad"
        "krita"
        "logi-options+"
        "monitorcontrol"
        "mqttx"
        "numi"
        "obs"
        "obsidian"
        "orcaslicer"
        "plex"
        "pycharm-ce"
        "raycast"
        "sublime-merge"
        "sublime-text"
        "transmission"
        "transmission-remote-gui"
        "vlc"
      ];
      brews = [
        "displayplacer"
        # "ffmpeg"
        "mas"
      ];
      masApps = {
        # NOTE - homebrew.masApps does not remove apps
        "1Password for Safari" = 1569813296;
        "Across" = 6444851827;
        "AdBlock Plus" = 1432731683;
        "Amphetamine" = 937984704;
        "GarageBand" = 682658836;
        "Goodnotes" = 1444383602;
        "Grab2Text" = 6475956137;
        "Home Assistant" = 1099568401;
        "iMovie" = 408981434;
        "Keynote" = 409183694;
        # "LiquidText" = 922765270;
        "Numbers" = 409203825;
        "Pages" = 409201541;
        "RECAP Uploader" = 1600281788;
        "The Camelizer" = 1532579087;
        "Things" = 904280696;
        "Xcode" = 497799835;
      };
    };

    system = {
      defaults = {
        dock = {
          tilesize = 16;
          persistent-apps = [
            "/System/Applications/Mail.app"
            "/Applications/Across.app"
            "/System/Applications/Calendar.app"
            "/Applications/Things3.app"
            "/System/Applications/Reminders.app"
            "/System/Applications/Messages.app"
            "/Applications/Safari.app"
            "/System/Applications/iPhone Mirroring.app"
            "/Applications/Claude.app"
          ];
          persistent-others = [
            "/Users/austin/Downloads"
          ];
        };
        finder = {
          ShowPathbar = true;
          ShowStatusBar = true;
        };

        CustomUserPreferences = {
          "com.apple.finder" = {
          };
          "com.apple.desktopservices" = {
            DSDontWriteNetworkStores = true;
            DSDontWriteUSBStores = true;
          };
          "com.apple.AdLib" = {
            allowApplePersonalizedAdvertising = false;
          };
          "com.apple.screensaver" = {
            askForPassword = 1;
            askForPasswordDelay = 10;
          };
        };
      };
    };
  })
  ####################
  #####  LINUX   #####
  ####################
  (lib.mkIf (!pkgs.stdenv.isDarwin) {
    home.packages = with pkgs; [
      blender
      dbeaver-bin
      freecad
      gimp
      gqrx
      inkscape
      kicad
      krita
      libreoffice-qt6-fresh
      obs-studio
      obsidian
      openscad
      orca-slicer
      plex-media-player
      rtl-sdr
      vlc
      vscodium-fhs
    ];
  })
]
# vim: set tabstop=2 softtabstop=2 shiftwidth=2 expandtab

