# users/austin/darwin/presets.nix
# Craft application presets for Apple Silicon Macs.
{ config
, lib
, autopkgs
, osConfig ? { }
, pkgs
, ...
}:
let
  presets = osConfig._astn.presets or { };
  isAppleSilicon = pkgs.stdenv.hostPlatform.system == "aarch64-darwin";
in
lib.mkIf isAppleSilicon {
  home.packages = lib.flatten [
    (lib.optionals (presets.graphics.enable or false) [
      autopkgs.photocraft
      autopkgs.lightcraft
      autopkgs.vectorcraft
      autopkgs.designcraft
      autopkgs.figcraft
      autopkgs.filmcraft
      autopkgs.effectcraft
      autopkgs.craft-fonts
    ])
    (lib.optionals (presets.maker.enable or false) [
      autopkgs.cadcraft
      autopkgs.constructcraft
      autopkgs.craft-fonts
    ])
    (lib.optionals (presets.recording.enable or false) [
      autopkgs.soundcraft
      autopkgs.craft-fonts
    ])
    (lib.optionals (presets.office.enable or false) [
      autopkgs.pdfcraft
      autopkgs.deckcraft
      autopkgs.gridcraft
      autopkgs.wordcraft
      autopkgs.craft-fonts
    ])
  ];
}
