# systems/darwin/homebrew.nix
{ ... }: {
  homebrew = {
    enable = true;

    # Do not force upgrades for unversioned or self-updating casks. Package
    # upgrades are intentionally left for an explicit `brew upgrade`.
    greedyCasks = false;

    onActivation = {
      autoUpdate = true; # Run `brew update` before activation
      upgrade = false; # Report available updates without installing them
      # NOTE: `cleanup` is deliberately left unset here so the user layer
      # decides (users/*/darwin/homebrew.nix uses "zap"); defining it in
      # both layers is an option-definition conflict.
    };
  };
}
