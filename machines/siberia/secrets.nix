# machines/siberia/secrets.nix
{ ... }:

{
  # Siberia-specific agenix secrets configuration
  age.secrets = {
    # Syncthing secrets for Siberia (consolidated JSON)
    syncthing-siberia = {
      file = ../../secrets/syncthing/config-siberia.age;
      mode = "0400";
      owner = "austin";
      group = "users";
    };

  };
}
