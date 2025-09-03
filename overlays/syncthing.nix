# overlays/syncthing.nix
# Temporary overlay to pin Syncthing to 1.30.0
# Last version before 2.0.x breaking changes, fixes Intel Mac build issues
# TODO: Remove once home-manager PR #7766 is merged and we're ready for 2.0.x
final: prev: {
  syncthing = prev.syncthing.overrideAttrs (oldAttrs: rec {
    version = "1.30.0";
    src = prev.fetchFromGitHub {
      owner = "syncthing";
      repo = "syncthing";
      rev = "v${version}";
      hash = "sha256-GKyzJ2kzs2h/tfb3StSleGBofiKk6FwVcSkCjsJRvRY=";
    };
    vendorHash = "sha256-Soky/3wEmP1QRy8xfL68sTHi3CSl4nbCINmG0DY2Qys=";
  });
}
