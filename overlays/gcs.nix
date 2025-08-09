# overlays/gcs.nix
# In ~/Documents/90__CONFIG/NX - NIX/overlays/gcs.nix
final: prev: {
  gcs = final.buildGoModule rec {
    pname = "gcs";
    version = "5.37.1";

    src = final.fetchFromGitHub {
      owner = "richardwilkes";
      repo = "gcs";
      rev = "v${version}";
      hash = "sha256-VHysS1/LxtVIJvnlw1joFPc+8uS525VK+FpmKoSikp0=";
    };

    modPostBuild = ''
      chmod +w vendor/github.com/richardwilkes/pdf
      sed -i 's|-lmupdf[^ ]* |-lmupdf |g' vendor/github.com/richardwilkes/pdf/pdf.go
    '';

    vendorHash = "sha256-T6Omz/jsk0raGM8p+G2wlMWRHzpo2qcTOtCddQoa83w=";

    nativeBuildInputs = [ final.pkg-config ];

    buildInputs = [
      final.mupdf
    ]
    ++ final.lib.optionals final.stdenv.hostPlatform.isLinux [
      final.libGL
      final.xorg.libX11
      final.xorg.libXcursor
      final.xorg.libXrandr
      final.xorg.libXinerama
      final.xorg.libXi
      final.xorg.libXxf86vm
      final.fontconfig
      final.freetype
    ];

    flags = [ "-a" ];
    ldflags = [
      "-s"
      "-w"
      "-X github.com/richardwilkes/toolbox/v2/xos.AppVersion=${version}"
    ];

    installPhase = ''
      runHook preInstall
      install -Dm755 $GOPATH/bin/gcs -t $out/bin
      runHook postInstall
    '';

    meta = with final.lib; {
      changelog = "https://github.com/richardwilkes/gcs/releases/tag/v${version}";
      description = "Stand-alone, interactive, character sheet editor for the GURPS 4th Edition roleplaying game system";
      homepage = "https://gurpscharactersheet.com/";
      license = licenses.mpl20;
      mainProgram = "gcs";
      maintainers = with maintainers; [ tomasajt ];
      platforms = platforms.linux ++ platforms.darwin;
      broken = final.stdenv.hostPlatform.isLinux && final.stdenv.hostPlatform.isAarch64;
    };
  };
}
