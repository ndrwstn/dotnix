# systems/darwin/homebrew.nix
{ ... }: {
  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = true; # Run `brew update` before activation
      upgrade = true; # Run `brew upgrade` for outdated packages
      cleanup = "uninstall"; # Remove unlisted packages (preserves app data)
    };
  };
}


