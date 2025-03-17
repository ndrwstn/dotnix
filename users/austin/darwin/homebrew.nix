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
      # "calibre"
      # "cleanshot"
      "claude"
      # "daisydisk"
      # "clop"
      # "find-any-file"
      # "maccy"
      # "araxis-merge"
      "balenaetcher"
      # "blender"
      "brave-browser"
      # "carbon-copy-cloner"
      "dbeaver-community"
      # "discord"
      # "freecad"
      "eloston-chromium"
      # "forklift"
      # "gimp"
      # "gqrx"
      "ghostty"
      # "inkscape"
      # "iina"
      "jdownloader"
      "jordanbaird-ice"
      "keka"
      # "kicad"
      # "krita"
      "little-snitch"
      # "localsend"
      "logi-options+"
      "monitorcontrol"
      "moom"
      "mqttx"
      "neovide"
      # "numi"
      # "obs"
      "obsidian"
      "orcaslicer"
      "pearcleaner"
      # "pdf-expert"
      "megasync"
      "home-assistant"
      # "hazel"
      "gcs"
      # "firefox"
      # "dropzone"
      "dropbox"
      "google-drive"
      # "plex"
      # "pycharm-ce"
      "raycast"
      "sublime-merge"
      "sublime-text"
      # "stremio"
      # "soundsource"
      # "soulver"
      # "skim"
      # "textual"
      # "privatevpn"
      "postgres-unofficial"
      "transmission"
      "transmission-remote-gui"
      "vlc"
      "zoom"
    ];
    brews = [
      "displayplacer"
      "ffmpeg"
      "mas"
    ];
    masApps = {
      # NOTE - homebrew.masApps does not remove apps
      "1Password for Safari" = 1569813296;
      "Across" = 6444851827;
      "AdBlock Plus" = 1432731683;
      "Amphetamine" = 937984704;
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
