# users/austin/nixos/presets/maker.nix
# CAD, electronics, and maker application preset.
{ pkgs
, ...
}:

{
  home.packages = with pkgs; [
    cloudcompare
    freecad
    kicad
    ltspice
    meshlab
    openscad
    orca-slicer
  ];
}
