{ config
, options
, pkgs
, lib
, autopkgs
, ...
}: {
  options.llm = {
    enable = lib.mkEnableOption "LLM tooling";

    llamaCpp.enable = lib.mkEnableOption "llama.cpp";
    mlxLm.enable = lib.mkEnableOption "mlx-lm";
    lmStudio.enable = lib.mkEnableOption "LM Studio";
  };

  config =
    let
      cfg = config.llm;
      hasHomebrew = options ? homebrew;
      isAppleSiliconDarwin = config._astn.machineSystem or null == "aarch64-darwin";
    in
    lib.mkIf cfg.enable (lib.mkMerge (
      [
        {
          assertions = [
            {
              assertion = !cfg.mlxLm.enable || isAppleSiliconDarwin;
              message = "llm.mlxLm.enable is only supported on aarch64-darwin.";
            }
            {
              assertion = !cfg.lmStudio.enable || isAppleSiliconDarwin;
              message = "llm.lmStudio.enable is only supported on aarch64-darwin.";
            }
          ];
        }

        (lib.mkIf cfg.llamaCpp.enable {
          environment.systemPackages = [
            pkgs."llama-cpp"
          ];
        })

        (lib.mkIf cfg.mlxLm.enable {
          environment.systemPackages = [
            autopkgs."mlx-lm"
          ];
        })
      ]
      ++ lib.optionals hasHomebrew [
        (lib.mkIf cfg.lmStudio.enable {
          homebrew.casks = [
            "lm-studio"
          ];
        })
      ]
    ));
}
