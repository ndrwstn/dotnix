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
  opencode = inputs.opencode.packages.${final.system}.default.overrideAttrs (old: {
    node_modules = old.node_modules.overrideAttrs (oldDeps: {
      # The `__noChksum = true` flag was not sufficient. The flake explicitly
      # passes a hash from hashes.json. We will force the hash attributes
      # to be null, converting this from a fixed-output derivation into a
      # regular one, which bypasses the hash check entirely.
      outputHash = null;
      outputHashMode = null;
      outputHashAlgo = null;
    });
  });
}
# vim: set tabstop=2 softtabstop=2 shiftwidth=2 expandtab
