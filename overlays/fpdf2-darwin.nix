# Temporary workaround for fpdf2's Darwin test comparison.
#
# fpdf2's explicit-dimensions PDF fixture is not identical on aarch64-darwin,
# even after qpdf normalization: the embedded image stream differs. Disable
# only that platform-specific fixture test while retaining the other checks.
# Remove this overlay once nixpkgs or fpdf2 handles this platform difference.

{ mkHack }:

let
  overlay = final: prev: {
    # Extend Python scopes before python3.pkgs and top-level applications such
    # as ocrmypdf are constructed.  Replacing python3Packages afterwards does
    # not rewrite those already-created aliases.
    pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
      (pythonFinal: pythonPrev: {
        fpdf2 = pythonPrev.fpdf2.overridePythonAttrs (old: {
          disabledTests = (old.disabledTests or [ ]) ++ [
            "test_image_with_explicit_dimensions"
          ];
        });
      })
    ];
  };
in
{
  hack = mkHack {
    name = "fpdf2-darwin-tests";
    reviewAfter = "2026-12-01";
    description = "fpdf2's explicit-dimensions PDF fixture differs on aarch64-darwin even after qpdf normalization; disable only that fixture test.";
  };

  inherit overlay;
}
