# users/austin/nixos/packages.nix
{ config
, pkgs
, unstable
, ...
}: {
  home.packages = with pkgs; [
    _1password-cli
    _1password-gui
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
    # plex-media-player  # removed from nixpkgs
    python313
    rtl-sdr
    ungoogled-chromium
    vlc
    vscodium-fhs
    wl-clipboard
    zathura
    ## Hyprland and Wayland utilities
    mako
    waybar
    wofi
    polkit_gnome
    grim
    slurp
    light
    swww
    ## unstable
    unstable.ghostty
  ];
}
