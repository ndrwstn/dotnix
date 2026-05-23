# users/austin/nixos/packages.nix
{ config
, pkgs
, ...
}: {
  home.packages = with pkgs; [
    # calibre ## fails to build 2025-08-31
    dbeaver-bin
    # plex-desktop
    vscodium-fhs
  ];
}
