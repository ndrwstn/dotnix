# machines/siberia/secrets.nix
{ ... }:

{
  # Siberia-specific agenix secrets configuration
  age.secrets = {
    # SSH setup key for remote access
    ssh-setup = {
      file = ../../secrets/ssh-setup.age;
      mode = "0400";
      owner = "austin";
      group = "users";
    };

    # Syncthing secrets for Siberia (consolidated JSON)
    syncthing-siberia = {
      file = ../../secrets/syncthing-siberia.age;
      mode = "0400";
      owner = "austin";
      group = "users";
    };
  };
}
