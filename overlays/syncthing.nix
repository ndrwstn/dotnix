# overlays/syncthing.nix
# Temporary overlay to pin Syncthing to 1.29.6
# Fixes Intel Mac crash (present in 1.29.5) while avoiding 2.0.x breaking changes
# TODO: Remove once home-manager PR #7766 is merged and we're ready for 2.0.x
final: prev: {
  syncthing = prev.syncthing.overrideAttrs (oldAttrs: rec {
    version = "1.29.6";
    src = prev.fetchFromGitHub {
      owner = "syncthing";
      repo = "syncthing";
      rev = "v${version}";
      hash = "sha256-gL5gTvZUSOj3EKVtMGcgPf5jw5XGdxlWVB65T2T2sFQ=";
    };
    vendorHash = "sha256-e8b9XQk0xpGr9Ys1J6/OaaqWaQJqzBjoBeIA5vGcGt4=";
  });
}
