# machines/plutonium/secrets.nix
{ ... }:

{
  # Plutonium-specific agenix secrets configuration
  age.secrets = {
    # SSH setup key for remote access
    ssh-setup = {
      file = ../../secrets/ssh-setup.age;
      mode = "0400";
      owner = "austin";
      group = "staff";
    };

    # Syncthing secrets for Plutonium (consolidated JSON)
    syncthing-plutonium = {
      file = ../../secrets/syncthing-plutonium.age;
      mode = "0400";
      owner = "austin";
      group = "staff";
    };
  };
}
