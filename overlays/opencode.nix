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
    # Disable hash checking for non-deterministic npm dependencies
    # The build produces different hashes on every run, making it impossible
    # to specify a correct hash. Observed hashes include:
    # - sha256-r3UEia5oE0EbBXmrydWlRPfWkk3W+Bqbmh7HpRKF5GM=
    # - sha256-bSlwyL7W7RutOHdYz7cOCXXYDg7HoQmgSxLNgLsU56w=
    # - sha256-lwIOD8TQzKd9CuhAztBVDdlWMd3Hn/vIjJdJ9W+54zY=
    # - sha256-Mt06nci5aMsb9kkrS8tDH1n6+Fvr9RRCJgD64A90rko= (upstream hardcoded)

    npmDepsHash = final.lib.fakeSha256;
    __noChksum = true;
  });
}
# vim: set tabstop=2 softtabstop=2 shiftwidth=2 expandtab
