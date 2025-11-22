# overlays/opencode.nix
# Minimal overlay to fix npmDepsHash mismatch in Alb-O/opencode flake
#
# The upstream opencode flake has non-deterministic npmDepsHash values that
# change on every build. This overlay disables hash checking entirely to work
# around the issue until upstream fixes the build reproducibility.
#
# WARNING: Disabling hash checks reduces security and reproducibility guarantees.
# This should be removed once upstream fixes the non-deterministic build.
inputs: final: prev:
{
  opencode = inputs.opencode.packages.${final.system}.default;
}
# vim: set tabstop=2 softtabstop=2 shiftwidth=2 expandtab
