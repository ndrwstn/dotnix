# users/austin/nixos/presets/maker.nix
# CAD, electronics, and maker application preset.
{ pkgs
, ...
}:

{
  home.packages = with pkgs; [
    freecad
    kicad
    ltspice
    openscad
    orca-slicer
  ];
}
