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
    # 1Password SSH agent socket for macOS
    SSH_AUTH_SOCK = "$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock";
    # Set locale to UTF-8
    LANG = "en_US.UTF-8";
  };
}
