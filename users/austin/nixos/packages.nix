{
  config,
  pkgs,
  ...
}: {
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
}