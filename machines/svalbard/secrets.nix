# machines/svalbard/secrets.nix
{ ... }:

{
  # Svalbard-specific agenix secrets configuration
  age.secrets = {
    # Syncthing secrets for Svalbard (consolidated JSON)
    syncthing-svalbard = {
      file = ../../secrets/syncthing/config-svalbard.age;
      mode = "0400";
      owner = "austin";
      group = "users";
    };
  };
}
