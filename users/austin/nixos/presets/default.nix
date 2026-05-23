# users/austin/nixos/presets/default.nix
# Optional NixOS Home Manager application presets.
{ config
, pkgs
, unstable
, lib
, osConfig ? { }
, ...
}:

let
  presets = osConfig._astn.presets or { };
in
lib.mkMerge [
  (lib.mkIf (presets.gui.enable or false)
    (import ./gui.nix { inherit config pkgs unstable lib; }))

  (lib.mkIf (presets.graphics.enable or false)
    (import ./graphics.nix { inherit config pkgs unstable lib; }))

  (lib.mkIf (presets.maker.enable or false)
    (import ./maker.nix { inherit config pkgs unstable lib; }))

  (lib.mkIf (presets.recording.enable or false)
    (import ./recording.nix { inherit config pkgs unstable lib; }))

  (lib.mkIf (presets.office.enable or false)
    (import ./office.nix { inherit config pkgs unstable lib; }))

  (lib.mkIf (presets.radio.enable or false)
    (import ./radio.nix { inherit config pkgs unstable lib; }))
]
