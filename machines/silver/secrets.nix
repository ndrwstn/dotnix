# machines/silver/secrets.nix
{ ... }:

{
  # Silver-specific agenix secrets configuration
  age.secrets = {
    # SSH setup key for remote access
    ssh-setup = {
      file = ../../secrets/ssh-setup.age;
      mode = "0400";
      owner = "austin";
      group = "users";
    };

    # Syncthing secrets for Silver (consolidated JSON)
    syncthing-silver = {
      file = ../../secrets/syncthing-silver.age;
      mode = "0400";
      owner = "austin";
      group = "users";
    };


  };
}
