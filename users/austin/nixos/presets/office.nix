# users/austin/nixos/presets/office.nix
# Office application preset.
{ pkgs
, ...
}:

{
  home.packages = with pkgs; [
    libreoffice-qt6-fresh
  ];
}
