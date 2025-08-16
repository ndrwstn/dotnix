# overlays/opencode.nix
# Binary-based overlay for opencode v0.5.4
final: prev:
let
  version = "0.5.4";

  # Platform-specific binary URLs and hashes
  platformMeta = {
    "aarch64-darwin" = {
      url = "https://github.com/sst/opencode/releases/download/v${version}/opencode-darwin-arm64.zip";
      hash = "sha256-fntpMG5W82SfU7Hk09yflegHoLHLEgzgOmLtO0AD8qE=";
    };
    "x86_64-darwin" = {
      url = "https://github.com/sst/opencode/releases/download/v${version}/opencode-darwin-x64.zip";
      hash = "sha256-NL34y5CW53cwoE2esOr/mrqiFCykdzDJx2j74z37R1c=";
    };
    "x86_64-linux" = {
      url = "https://github.com/sst/opencode/releases/download/v${version}/opencode-linux-x64.zip";
      hash = "sha256-PBWaduD18DFebUPLkRz7AGbOiHGGcqrrG30y6J6b+9M=";
    };
    "aarch64-linux" = {
      url = "https://github.com/sst/opencode/releases/download/v${version}/opencode-linux-arm64.zip";
      hash = "sha256-/Mx3e0bTlfbwBHPO+eNZ1jYQ5Oiqas7WPjYmcxz4yg8=";
    };
  };

  # Get current platform metadata
  platform = final.stdenv.hostPlatform.system;
  meta = platformMeta.${platform} or (throw "Unsupported platform: ${platform}");
in
{
  opencode = final.stdenv.mkDerivation {
    pname = "opencode";
    inherit version;

    src = final.fetchurl {
      url = meta.url;
      hash = meta.hash;
    };

    # Required for unzipping
    nativeBuildInputs = [ final.unzip ];

    # No need for source unpacking, we'll handle it in installPhase
    dontUnpack = true;

    installPhase = ''
      runHook preInstall
      
      # Create output directory
      mkdir -p $out/bin
      
      # Extract the zip file
      unzip $src
      
      # Install the binary
      install -m755 opencode $out/bin/opencode
      
      runHook postInstall
    '';

    meta = with final.lib; {
      description = "AI coding agent built for the terminal";
      longDescription = ''
        OpenCode is a terminal-based agent that can build anything.
        It combines a TypeScript/JavaScript core with a Go-based TUI
        to provide an interactive AI coding experience.
      '';
      homepage = "https://github.com/sst/opencode";
      license = licenses.mit;
      platforms = platforms.unix;
      mainProgram = "opencode";
    };
  };
}
# vim: set tabstop=2 softtabstop=2 shiftwidth=2 expandtab
