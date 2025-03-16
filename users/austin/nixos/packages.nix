# users/austin/nixos/packages.nix
{
  config,
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
    alsa-utils
    blender
    # calibre
    dbeaver-bin
    freecad
    gimp
    gqrx
    inkscape
    kicad
    krita
    libreoffice-qt6-fresh
    neovide
    obs-studio
    obsidian
    openscad
    orca-slicer
    plex-media-player
    rtl-sdr
    vlc
    vscodium-fhs
    wl-clipboard
    ## unstable
    unstable.ghostty
  ];
}
