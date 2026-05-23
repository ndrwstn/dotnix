# systems/nixos/presets/default.nix
# System-level preset consumers.
{
  imports = [
    ./radio.nix
  ];
}
