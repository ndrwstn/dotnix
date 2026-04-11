# users/austin/nixos/packages.nix
{ config
, pkgs
, unstable
, ...
}: {
  home.packages = with pkgs; [
    alsa-utils
    blender
    # calibre ## fails to build 2025-08-31
    dbeaver-bin
    freecad
    # ghostty
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
    # plex-desktop
    python313
    rtl-sdr
    ungoogled-chromium
    vlc
    vscodium-fhs
    wl-clipboard
    zathura
    ## Hyprland and Wayland utilities
    blueman
    mako
    cliphist
    waybar
    polkit_gnome
    grim
    slurp
    brightnessctl
    light
    networkmanagerapplet
    pavucontrol
    swww
    matugen
    ## unstable
    unstable.ghostty
  ];
}
