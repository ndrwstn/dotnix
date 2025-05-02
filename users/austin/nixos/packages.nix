# users/austin/nixos/packages.nix
{
  config,
  pkgs,
  # unstable,
  ...
}: {
  home.packages = with pkgs; [
    alsa-utils
    blender
    calibre
    dbeaver-bin
    freecad
    gimp
    ghostty
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
    zathura
    zathura-pdf-mupdf
    ## unstable
  ];
}
