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
      "appcleaner"
      # "calibre"
      "claude"
      # "balenaetcher"
      # "blender"
      # "brave-browser"
      # "chromium" # NOTE -- not installed in favor of 'elonston-chromium' (ungoogled version)
      # "dbeaver-community"
      # "discord"
      # "eloston-chromium" # NOTE -- ungoogled version?
      # "freecad"
      # "gimp"
      # "gqrx"
      "ghostty"
      # "inkscape"
      # "jdownloader"
      # "jordanbaird-ice"
      "keka"
      # "kicad"
      # "krita"
      "logi-options+"
      "monitorcontrol"
      # "mqttx"
      "neovide"
      # "numi"
      # "obs"
      # "obsidian"
      # "orcaslicer"
      # "plex"
      # "pycharm-ce"
      # "raycast"
      "sublime-merge"
      "sublime-text"
      # "transmission"
      # "transmission-remote-gui"
      # "vlc"
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
