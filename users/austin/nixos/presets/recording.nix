# users/austin/nixos/presets/recording.nix
# Screen/video recording application preset.
{ pkgs
, ...
}:

{
  home.packages = with pkgs; [
    obs-studio
  ];
}
