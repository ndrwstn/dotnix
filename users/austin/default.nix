{
  config,
  pkgs,
  unstable,
  ...
}: {
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
    # ansible
    # blender
    # calibre
    # cloudflared
    dbeaver-bin
    docker
    eza
    ffmpeg_7
    fluxcd
    # freecad
    # gimp
    gcc
    go-task
    gqrx
    # inkscape
    jq
    # kicad
    # krita
    kubeconform
    kubectl
    kubernetes-helm
    kustomize
    libreoffice-qt6-fresh
    moreutils
    neovide
    nmap
    nodejs_22
    # obs-studio
    obsidian
    # openscad
    # orca-slicer
    # plex-media-player
    printrun
    python3
    rsync
    rtl-sdr
    sops
    stern
    talosctl
    thefuck
    tlrc
    # tldr
    tree-sitter
    ungoogled-chromium
    vlc
    vscodium-fhs
    wl-clipboard
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
# vim: set tabstop=2 softtabstop=2 shiftwidth=2 expandtab

