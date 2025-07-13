# users/austin/nixos/packages.nix
{ config
, pkgs
, # unstable,
  ...
}: {
  home.packages = with pkgs; [
    alsa-utils
    blender
    calibre
    dbeaver-bin
    freecad
    gcs
    ghostty
    gimp
    gqrx
    inkscape
    kicad
    krita
    libreoffice-qt6-fresh
    minicom
    neovide
    obs-studio
    obsidian
    openscad
    orca-slicer
    plex-media-player
    python313
    rtl-sdr
    vlc
    vscodium-fhs
    wl-clipboard
    zathura
    ## unstable
  ];
}
