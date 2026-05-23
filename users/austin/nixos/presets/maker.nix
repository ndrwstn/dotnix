# users/austin/nixos/presets/maker.nix
# CAD, electronics, and maker application preset.
{ pkgs
, ...
}:

{
  home.packages = with pkgs; [
    freecad
    kicad
    openscad
    orca-slicer
  ];
}
