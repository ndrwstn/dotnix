# users/austin/nixos/presets/graphics.nix
# Graphics application preset.
{ pkgs
, ...
}:

{
  home.packages = with pkgs; [
    blender
    gimp
    inkscape
    krita
  ];
}
