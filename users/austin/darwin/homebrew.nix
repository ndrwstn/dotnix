# users/austin/darwin/homebrew.nix
{ config
, pkgs
, ...
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
      "1password-cli"
      # "araxis-merge"
      "balenaetcher"
      "blender"
      "brave-browser"
      "calibre"
      "carbon-copy-cloner"
      "claude"
      # "cleanshot"
      # "clop"
      # "daisydisk"
      "dbeaver-community"
      "discord"
      "dropbox"
      # "dropzone"
      # "find-any-file"
      # "firefox"
      # "forklift"
      # "freecad"
      "ghostty"
      # "gimp"
      "google-drive"
      # "gqrx"
      # "halloy" # 2025-05-18 doesn't connect to irchighway.net
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
      # "numi"
      "obs"
      "obsidian"
      "ollamac"
      "orcaslicer"
      # "pdf-expert"
      "pearcleaner"
      # "plex"
      "postgres-unofficial"
      # "privatevpn" # 2023-03-16 does not work - "can't communicate with helper application"
      # "pycharm-ce"
      "qlmarkdown"
      "raycast"
      "skim"
      # "soulver"
      # "soundsource"
      # "stremio"
      "sublime-merge"
      "sublime-text"
      "textual"
      "transmission"
      "transmission-remote-gui"
      "ungoogled-chromium"
      "vlc"
      "zen"
      "zoom"
    ];
    brews = [
      "displayplacer"
      "ffmpeg"
      "tag"
      # "m1ddc"
      "mas"
      "ollama"
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
