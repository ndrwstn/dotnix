# Temporary workaround for fpdf2's Darwin test comparison.
#
# fpdf2 falls back to byte-for-byte PDF comparisons when qpdf is unavailable
# in the build sandbox.  The explicit-dimensions test is not byte-identical on
# aarch64-darwin, so provide qpdf to the test environment and let fpdf2 use its
# normalized comparison path instead.
# Remove this overlay once nixpkgs or fpdf2 handles this platform difference.

{ mkHack }:

{
  hack = mkHack {
    name = "fpdf2-darwin-tests";
    reviewAfter = "2026-12-01";
    description = "fpdf2 needs qpdf in its Darwin test environment because byte-for-byte PDF comparisons fail on aarch64-darwin.";
  };

  overlay = final: prev: {
    python313Packages = prev.python313Packages.overrideScope
      (pythonFinal: pythonPrev: {
        fpdf2 = pythonPrev.fpdf2.overridePythonAttrs (old: {
          nativeCheckInputs = (old.nativeCheckInputs or [ ]) ++ [ final.qpdf ];
        });
      });
  };
}
