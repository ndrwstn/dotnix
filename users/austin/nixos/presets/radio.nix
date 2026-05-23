# users/austin/nixos/presets/radio.nix
# Radio/SDR user application preset.
{ pkgs
, ...
}:

{
  home.packages = with pkgs; [
    gqrx
    minicom
    rtl-sdr
  ];
}
