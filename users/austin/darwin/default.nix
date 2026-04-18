# users/austin/darwin/default.nix
{ config
, pkgs
, lib
, autopkgs
, ...
}:
lib.mkMerge [
  # TODO: Flake architecture issue - darwin/default.nix is evaluated even on NixOS
  # systems, so we need this extra isDarwin check. This should be fixed at the flake
  # level so darwin-specific modules are never evaluated on non-Darwin systems.
  (lib.mkIf pkgs.stdenv.isDarwin
    (lib.mkMerge [
      (import ./appprefs.nix { inherit config lib pkgs; })
      (lib.mkIf (pkgs.stdenv.hostPlatform.system == "aarch64-darwin")
        (import ./apple-silicon.nix { inherit config lib pkgs autopkgs; }))
      (import ./keyboard.nix { inherit config lib pkgs; })
    ]))

  # Environmental Variables
  {
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
]
