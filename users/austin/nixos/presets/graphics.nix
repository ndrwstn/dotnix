# users/austin/nixos/presets/graphics.nix
# Graphics application preset.
{ pkgs
, autopkgs
, ...
}:

{
  home.packages = with pkgs; [
    blender
    autopkgs.photocraft
    autopkgs.lightcraft
    autopkgs.vectorcraft
    autopkgs.designcraft
    autopkgs.figcraft
    autopkgs.filmcraft
    autopkgs.effectcraft
    autopkgs.craft-fonts
    gimp
    inkscape
    krita
  ];
}
