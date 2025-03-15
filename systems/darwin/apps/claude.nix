# systems/darwin/apps/claude.nix
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.darwin.apps.claude;
in {
  options = {
    darwin.apps.claude = {
      enable = mkEnableOption "Claude AI desktop app";
    };
  };

  config = mkIf cfg.enable {
    nixpkgs.overlays = [
      (final: prev: {
        claude = final.callPackage (
          {
            lib,
            stdenv,
            undmg,
            fetchurl,
          }:
            stdenv.mkDerivation rec {
              pname = "claude";
              version = "0.8.1";

              src = fetchurl {
                url = "https://storage.googleapis.com/osprey-downloads-c02f6a0d-347c-492b-a752-3e0651722e97/nest/Claude.dmg";
                sha256 = "sha256-p0zPXBAXz+F871pN12565gfa3f00skcVEgmwKn8sxj8=";
              };

              nativeBuildInputs = [undmg];

              sourceRoot = ".";

              installPhase = ''
                runHook preInstall
                mkdir -p $out/Applications
                cp -r Claude.app $out/Applications/
                runHook postInstall
              '';

              meta = with lib; {
                description = "Claude for Desktop";
                homepage = "https://claude.ai";
                platforms = platforms.darwin;
                license = licenses.unfree;
              };
            }
        ) {};
      })
    ];

    environment.systemPackages = [pkgs.claude];

    system.activationScripts.postActivation.text = mkAfter ''
      # Setup Claude.app
      echo "setting up Claude.app..."
      rm -rf /Applications/Claude.app
      ln -sf ${placeholder "out"}/Applications/Claude.app /Applications/Claude.app
    '';
  };
}
