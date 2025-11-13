# overlays/opencode.nix
# Minimal overlay to fix npmDepsHash mismatch in Alb-O/opencode flake
#
# This overlay overrides the opencode package from the flake input to fix
# hash mismatches. When upstream fixes the hash, this overlay can be removed.
inputs: final: prev:
{
  opencode = inputs.opencode.packages.${final.system}.default.overrideAttrs (old: {
    # Known hashes for different branches/situations:
    # Uncomment the correct hash if the current one fails

    # COMPUTED HASHES (what Nix actually gets):
    # sha256-r3UEia5oE0EbBXmrydWlRPfWkk3W+Bqbmh7HpRKF5GM= - nix-support branch (current)
    # sha256-3uktWyGvmx+ERQ/tybq2xuD9lGWm6UkhSD1Nj+Dhl10= - debug/node-modules-hash branch

    # HARDCODED HASHES (what's in the flake - WRONG):
    # sha256-Mt06nci5aMsb9kkrS8tDH1n6+Fvr9RRCJgD64A90rko= - nix-support hardcoded (incorrect)
    # sha256-bBXTToF+8hVTLzF/Ea+bpy/CzQyOYeCqBB96neM50JU= - debug branch hardcoded (incorrect)

    npmDepsHash = "sha256-r3UEia5oE0EbBXmrydWlRPfWkk3W+Bqbmh7HpRKF5GM=";
  });
}
# vim: set tabstop=2 softtabstop=2 shiftwidth=2 expandtab
