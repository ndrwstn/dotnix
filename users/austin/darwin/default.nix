# users/austin/darwin/default.nix
{ config
, pkgs
, lib
, ...
}: {
  # Environmental Variables
  home.sessionVariables = {
    # Disable Homebrew analytics collection
    HOMEBREW_NO_ANALYTICS = 1;
    # Set default editor to nvim
    EDITOR = "nvim";
  };
}
