# systems/nixos/presets/radio.nix
# Radio/SDR system configuration.
{ config
, lib
, ...
}:

lib.mkIf config._astn.presets.radio.enable {
  hardware.rtl-sdr.enable = true;
}
