# Temporary workaround for fpdf2's Darwin test comparison.
#
# fpdf2 falls back to byte-for-byte PDF comparisons when qpdf is unavailable
# in the build sandbox.  The explicit-dimensions test is not byte-identical on
# aarch64-darwin, so provide qpdf to the test environment and let fpdf2 use its
# normalized comparison path instead.
# Remove this overlay once nixpkgs or fpdf2 handles this platform difference.

{ mkHack }:

let
  overlay = final: prev:
    let
      overrideFpdf2 = pythonPrev: pythonPrev.fpdf2.overridePythonAttrs (old: {
        nativeCheckInputs = (old.nativeCheckInputs or [ ]) ++ [ final.qpdf ];
      });
    in
    {
      # ocrmypdf resolves its dependencies through python3Packages, while the
      # resulting derivation is named python3.13-fpdf2.  Override both package
      # set entry points so the fix reaches either dependency path.
      python3Packages = prev.python3Packages.overrideScope
        (pythonFinal: pythonPrev: {
          fpdf2 = overrideFpdf2 pythonPrev;
        });
      python313Packages = prev.python313Packages.overrideScope
        (pythonFinal: pythonPrev: {
          fpdf2 = overrideFpdf2 pythonPrev;
        });
    };
in
{
  hack = mkHack {
    name = "fpdf2-darwin-tests";
    reviewAfter = "2026-12-01";
    description = "fpdf2 needs qpdf in its Darwin test environment because byte-for-byte PDF comparisons fail on aarch64-darwin.";
  };

  inherit overlay;
}
