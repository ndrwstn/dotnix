# machines/molybdenum/secrets.nix
{ ... }:

{
  # Molybdenum-specific agenix secrets configuration
  age.secrets = {
    # Syncthing secrets for Molybdenum (consolidated JSON)
    syncthing-molybdenum = {
      file = ../../secrets/syncthing/config-molybdenum.age;
      mode = "0400";
      owner = "austin";
      group = "users";
    };

  };
}
