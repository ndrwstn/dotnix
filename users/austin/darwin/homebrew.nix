# systems/darwin/homebrew.nix
{
  config,
  pkgs,
  ...
}: {
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      cleanup = "zap";
    };
    global = {
      brewfile = true;
    };
    casks = [
      "1password"
      # "araxis-merge"
      "balenaetcher"
      "blender"
      "brave-browser"
      # "calibre"
      "carbon-copy-cloner"
      "claude"
      # "cleanshot"
      # "clop"
      # "daisydisk"
      "dbeaver-community"
      "discord"
      "dropbox"
      # "dropzone"
      "eloston-chromium"
      # "find-any-file"
      # "firefox"
      # "forklift"
      # "freecad"
      "gcs"
      "ghostty"
      # "gimp"
      "google-drive"
      # "gqrx"
      "hazel"
      "home-assistant"
      # "iina"
      # "inkscape"
      "jdownloader"
      "jordanbaird-ice"
      "keka"
      # "kicad"
      # "krita"
      "little-snitch"
      # "localsend"
      "logi-options+"
      # "maccy"
      "megasync"
      "monitorcontrol"
      "moom"
      "mqttx"
      "name-mangler"
      "neovide"
      # "numi"
      "obs"
      "obsidian"
      "orcaslicer"
      # "pdf-expert"
      "pearcleaner"
      # "plex"
      "postgres-unofficial"
      # "privatevpn" # 2023-03-16 does not work - "can't communicate with helper application"
      # "pycharm-ce"
      "raycast"
      # "skim"
      # "soulver"
      # "soundsource"
      # "stremio"
      "sublime-merge"
      "sublime-text"
      # "textual"
      "transmission"
      "transmission-remote-gui"
      "vlc"
      "zen-browser"
      "zoom"
    ];
    brews = [
      "displayplacer"
      "ffmpeg"
      "tag"
      "mas"
    ];
    masApps = {
      # NOTE - homebrew.masApps does not remove apps
      "1Password for Safari" = 1569813296;
      "Across" = 6444851827;
      "AdBlock Plus" = 1432731683;
      "Amphetamine" = 937984704;
      "Banktivity" = 1480779512;
      # "GarageBand" = 682658836;
      "Goodnotes" = 1444383602;
      "Grab2Text" = 6475956137;
      "Home Assistant" = 1099568401;
      # "iMovie" = 408981434;
      # "Keynote" = 409183694;
      # "LiquidText" = 922765270;
      # "Numbers" = 409203825;
      # "Pages" = 409201541;
      "RECAP Uploader" = 1600281788;
      "The Camelizer" = 1532579087;
      "Things" = 904280696;
      # "Xcode" = 497799835;
    };
  };
}
