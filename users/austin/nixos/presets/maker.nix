# users/austin/nixos/presets/maker.nix
# CAD, electronics, and maker application preset.
{ pkgs
, autopkgs
, ...
}:

{
  home.packages = with pkgs; [
    cloudcompare
    autopkgs.cadcraft
    autopkgs.constructcraft
    autopkgs.craft-fonts
    autopkgs.solidcraft
    freecad
    kicad
    ltspice
    meshlab
    openscad
    orca-slicer
  ];
}
