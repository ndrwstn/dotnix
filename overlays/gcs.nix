# overlays/gcs.nix
final: prev: {
  gcs = prev.gcs.overrideAttrs
    (old: {
      version = "5.37.1";

      src = prev.fetchFromGitHub {
        owner = "richardwilkes";
        repo = "gcs";
        rev = "v5.37.1";
        hash = "sha256-VHysS1/LxtVIJvnlw1joFPc+8uS525VK+FpmKoSikp0=";
      };

      vendorHash = "sha256-hFgcTreiE2PwIwOG1zwLyF7ZbB+p9uCNVJcqHbQjJjE=";
    });
}
