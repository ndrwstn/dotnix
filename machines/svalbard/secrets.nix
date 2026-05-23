# machines/svalbard/secrets.nix
{ ... }:

{
  # Svalbard-specific agenix secrets configuration
  age.secrets = {
    # SSH setup key for remote access
    ssh-setup = {
      file = ../../secrets/ssh-setup.age;
      mode = "0400";
      owner = "austin";
      group = "users";
    };

    # Syncthing secrets for Svalbard (consolidated JSON)
    syncthing-svalbard = {
      file = ../../secrets/syncthing/config-svalbard.age;
      mode = "0400";
      owner = "austin";
      group = "users";
    };
  };
}
