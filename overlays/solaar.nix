# Temporary workaround for the Solaar 1.1.19 test failure in nixos-26.05.
#
# Added: 2026-10-17.  Solaar 1.1.19 fails its desktop-notification tests in
# the Nix sandbox because no machine-id is available.  Solaar 1.1.20 fixes
# this package-level problem and has been backported to release-26.05 in
# nixpkgs PR #574929, but the nixos-26.05 channel has not picked it up yet.
# Remove this overlay once stable nixpkgs provides Solaar >= 1.1.20.

{ lib, mkHack, nixpkgsUnstable }:

let
  minimumVersion = "1.1.20";
in
{
  hack = mkHack {
    name = "solaar-stable-package";
    reviewAfter = "2026-10-31";
    description = "Stable nixpkgs Solaar 1.1.19 fails notification tests without a machine-id; use Solaar >= 1.1.20 from nixpkgs-unstable until the stable channel advances.";
  };

  overlay = final: prev:
    let
      system = prev.stdenv.hostPlatform.system;
      replacement = (import nixpkgsUnstable {
        inherit system;
        config.allowUnfree = true;
      }).solaar;
    in
    {
      # Always use the known-good package during this temporary hack.  Remove
      # the whole overlay once stable nixpkgs has caught up.
      solaar = assert lib.versionAtLeast replacement.version minimumVersion; replacement;
    };
}
