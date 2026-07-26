# systems/common/secrets.nix
# Shared secrets configuration for all machines
#
# NOTE: Builder/virtual machines skip shared secrets (syncthing, atuin,
# general) since they have no use for them. Secrets are only deployed
# to desktop and laptop machines.

{ config, pkgs, lib, ... }:

let
  inherit (lib) mkIf;
  # Skip shared secrets on builder/virtual machines
  deploySharedSecrets = !(builtins.elem (config._astn.machineRole or "") [ "virtual" "template" ]);
in
{
  # Common identity paths for all systems
  age.identityPaths = [
    "/etc/ssh/ssh_host_ed25519_key"
  ];

  # Shared agenix secrets configuration
  age.secrets = {
    # Shared syncthing configuration
    syncthing = mkIf deploySharedSecrets {
      file = ../../secrets/syncthing/config-shared.age;
      mode = "0400";
      owner = "austin";
      group = if pkgs.stdenv.isDarwin then "staff" else "users";
    };

    # Atuin shell history sync
    atuin = mkIf deploySharedSecrets {
      file = ../../secrets/atuin.age;
      mode = "0400";
      owner = "austin";
      group = if pkgs.stdenv.isDarwin then "staff" else "users";
    };

    # Shared general secrets
    general = mkIf deploySharedSecrets {
      file = ../../secrets/general.age;
      mode = "0400";
      owner = "austin";
      group = if pkgs.stdenv.isDarwin then "staff" else "users";
    };
  };
}
