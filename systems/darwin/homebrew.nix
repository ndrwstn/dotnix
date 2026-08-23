# systems/darwin/homebrew.nix
{ ... }: {
  homebrew = {
    enable = true;

    # Do not force upgrades for unversioned or self-updating casks. Regular
    # versioned formulae and casks are still upgraded below.
    greedyCasks = false;

    onActivation = {
      autoUpdate = true; # Run `brew update` before activation
      upgrade = true; # Run `brew upgrade` for outdated packages
      # NOTE: `cleanup` is deliberately left unset here so the user layer
      # decides (users/*/darwin/homebrew.nix uses "zap"); defining it in
      # both layers is an option-definition conflict.
    };
  };
}
