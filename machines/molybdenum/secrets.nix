# machines/molybdenum/secrets.nix
{ ... }:

{
  # Molybdenum-specific agenix secrets configuration
  age.secrets = {
    # SSH setup key for remote access
    ssh-setup = {
      file = ../../secrets/ssh-setup.age;
      mode = "0400";
      owner = "austin";
      group = "users";
    };

    # Syncthing secrets for Molybdenum (consolidated JSON)
    syncthing-molybdenum = {
      file = ../../secrets/syncthing-molybdenum.age;
      mode = "0400";
      owner = "austin";
      group = "users";
    };

  };
}
