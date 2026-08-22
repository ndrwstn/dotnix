# systems/darwin/homebrew.nix
{ ... }: {
  homebrew = {
    enable = true;

    # Upgrade every listed cask during activation, including unversioned /
    # self-updating ones (`brew bundle` skips those without `greedy`).
    greedyCasks = true;

    onActivation = {
      autoUpdate = true; # Run `brew update` before activation
      upgrade = true; # Run `brew upgrade` for outdated packages
      # NOTE: `cleanup` is deliberately left unset here so the user layer
      # decides (users/*/darwin/homebrew.nix uses "zap"); defining it in
      # both layers is an option-definition conflict.
    };
  };
}
