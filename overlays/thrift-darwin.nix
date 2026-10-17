# Temporary workaround for nixpkgs' Darwin thrift packaging.
#
# When: added 2026-10-07 while nixpkgs' thrift 0.24.0 package set
# doCheck = false on Darwin but still passes BUILD_TESTING=TRUE to CMake.
# Why: that causes the bundled Catch v1 tests to compile and fail against
# the current Darwin libc++; markitdown depends on this package through
# arrow-cpp, so the failure blocks the entire Home Manager generation.
# Remove this overlay once the corresponding nixpkgs fix is available.

{ mkHack }:

{
  hack = mkHack {
    name = "thrift-darwin-tests";
    reviewAfter = "2026-12-01";
    description = "Darwin thrift tests are disabled because nixpkgs passes BUILD_TESTING=TRUE despite doCheck = false.";
  };

  overlay = final: prev: {
    thrift = prev.thrift.overrideAttrs (old: {
      cmakeFlags =
        builtins.filter
          (flag: !prev.lib.hasPrefix "-DBUILD_TESTING" flag)
          old.cmakeFlags
        ++ [ "-DBUILD_TESTING:BOOL=FALSE" ];
    });
  };
}
