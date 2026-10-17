{ mkHack, vicinae }:

let
  hack = mkHack {
    name = "vicinae-numen-build";
    reviewAfter = "2026-12-01";
    description = "Vicinae and Numen use matched toolchains, disable optional Numen components, and serialize their builds.";
  };
in
{
  inherit hack;

  overlay = final: prev:
    let
      system = prev.stdenv.hostPlatform.system;
      numen = (vicinae.inputs.numen.packages.${system}.default.override {
        stdenv = prev.stdenv;
        withRepl = false;
        withReplCurrencyProvider = false;
      }).overrideAttrs (old: {
        enableParallelBuilding = false;
        cmakeFlags = old.cmakeFlags ++ [ "-DCMAKE_BUILD_PARALLEL_LEVEL=1" ];
      });
    in
    {
      vicinae = (vicinae.packages.${system}.default.override { inherit numen; }).overrideAttrs (old: {
        enableParallelBuilding = false;
        cmakeFlags = old.cmakeFlags ++ [ "-DCMAKE_BUILD_PARALLEL_LEVEL=1" ];
      });
    };
}
