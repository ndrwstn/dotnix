# users/austin/nixos/presets/recording.nix
# Screen/video recording application preset.
{ pkgs
, autopkgs
, ...
}:

{
  home.packages = with pkgs; [
    obs-studio
    autopkgs.soundcraft
    autopkgs.craft-fonts
  ];
}
