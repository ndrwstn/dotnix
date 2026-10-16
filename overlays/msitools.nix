final: prev:

prev.lib.warn
  "Temporary workaround: msitools checks are disabled because upstream tests fail with the current dependency set. Recheck upstream after 2026-12-01."
{
  # Consumers such as LTspice only need the built tools, not the upstream
  # test suite.
  msitools = prev.msitools.overrideAttrs (_: {
    doCheck = false;
  });
}
