# systems/common/secrets.nix
# Shared secrets configuration for all machines

{ pkgs, ... }:

{
  # Shared agenix secrets configuration
  age.secrets = {
    # Shared syncthing configuration (all machines can decrypt)
    syncthing = {
      file = ../../secrets/syncthing.age;
      mode = "0400";
      owner = "austin";
      group = if pkgs.stdenv.isDarwin then "staff" else "users";
    };
  };
}
