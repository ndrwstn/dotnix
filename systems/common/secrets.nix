# systems/common/secrets.nix
# Shared secrets configuration for all machines
#
# NOTE: Secrets are deployed to ALL machines unconditionally. This could be
# optimized: builder/virtual machines don't need syncthing, atuin, or general
# secrets. Future: scope secrets by _astn.machineRole or use a more selective
# distribution mechanism. Needs more thoughtful consideration.

{ pkgs, ... }:

{
  # Common identity paths for all systems
  age.identityPaths = [
    "/etc/ssh/ssh_host_ed25519_key"
  ];

  # Shared agenix secrets configuration
  age.secrets = {
    # Shared syncthing configuration (all machines can decrypt)
    syncthing = {
      file = ../../secrets/syncthing/config-shared.age;
      mode = "0400";
      owner = "austin";
      group = if pkgs.stdenv.isDarwin then "staff" else "users";
    };

    # Atuin shell history sync (shared across all machines)
    atuin = {
      file = ../../secrets/atuin.age;
      mode = "0400";
      owner = "austin";
      group = if pkgs.stdenv.isDarwin then "staff" else "users";
    };

    # Shared general secrets (shared across all machines)
    general = {
      file = ../../secrets/general.age;
      mode = "0400";
      owner = "austin";
      group = if pkgs.stdenv.isDarwin then "staff" else "users";
    };
  };
}
