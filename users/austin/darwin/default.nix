# users/austin/darwin/default.nix
{ config
, pkgs
, lib
, autopkgs
, ...
}:
let
  onePasswordSshAuthSock = "${config.home.homeDirectory}/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock";
in
lib.mkMerge [
  # TODO: Flake architecture issue - darwin/default.nix is evaluated even on NixOS
  # systems, so we need this extra isDarwin check. This should be fixed at the flake
  # level so darwin-specific modules are never evaluated on non-Darwin systems.
  (lib.mkIf pkgs.stdenv.isDarwin
    (lib.mkMerge [
      (import ./group-container-prefs.nix { inherit config lib pkgs; })
      (import ./printing-presets.nix { inherit config lib pkgs; })
      (lib.mkIf (pkgs.stdenv.hostPlatform.system == "aarch64-darwin")
        (import ./apple-silicon.nix { inherit config lib pkgs autopkgs; }))

      # whisper.cpp with Metal acceleration (auto-enabled on aarch64-darwin).
      # Intel Macs deferred: CPU-only inference is too slow to be useful.
      # Future: remote inference via k8s OpenVINO cluster for Intel machines.
      {
        home.packages = with pkgs; [
          whisper-cpp
        ];
      }
    ]))

  # Environmental Variables
  {
    home.sessionVariables = {
      # Disable Homebrew analytics collection
      HOMEBREW_NO_ANALYTICS = 1;
      # Set default editor to nvim
      EDITOR = "nvim";
      # Set locale to UTF-8
      LANG = "en_US.UTF-8";
    };

    programs.zsh.initContent = lib.mkAfter ''
      # Use the local 1Password SSH agent in local shells, but do not override
      # sshd's forwarded SSH_AUTH_SOCK when this shell is running over SSH.
      if [ -z "$SSH_CONNECTION" ]; then
        export SSH_AUTH_SOCK="${onePasswordSshAuthSock}"
      fi
    '';
  }
]
