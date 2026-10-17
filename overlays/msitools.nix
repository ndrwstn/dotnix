{ mkHack }:

{
  hack = mkHack {
    name = "msitools-checks";
    reviewAfter = "2026-12-01";
    description = "msitools checks are disabled because upstream tests fail with the current dependency set.";
  };

  overlay = final: prev: {
    # Consumers such as LTspice only need the built tools, not the upstream
    # test suite.
    msitools = prev.msitools.overrideAttrs (_: {
      doCheck = false;
    });
  };
}
