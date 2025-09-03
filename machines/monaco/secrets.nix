# machines/monaco/secrets.nix
{ ... }:

{
  # Monaco-specific agenix secrets configuration
  age.secrets = {
    # SSH setup key for remote access
    ssh-setup = {
      file = ../../secrets/ssh-setup.age;
      mode = "0400";
      owner = "austin";
      group = "staff";
    };

    # Syncthing secrets for Monaco (consolidated JSON)
    syncthing-monaco = {
      file = ../../secrets/syncthing-monaco.age;
      mode = "0400";
      owner = "austin";
      group = "staff";
    };
  };
}
