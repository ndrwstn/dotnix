# overlays/opencode.nix
# Flake-based overlay using forked opencode-nix repository
inputs: final: prev:
{
  opencode = inputs.opencode-nix.packages.${final.system}.default;
}
# vim: set tabstop=2 softtabstop=2 shiftwidth=2 expandtab
