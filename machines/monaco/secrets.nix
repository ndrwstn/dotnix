# machines/monaco/secrets.nix
{ ... }:

{
  # Monaco-specific agenix secrets configuration
  age.secrets = {
    # Syncthing secrets for Monaco (consolidated JSON)
    syncthing-monaco = {
      file = ../../secrets/syncthing/config-monaco.age;
      mode = "0400";
      owner = "austin";
      group = "staff";
    };

    # naphthalene remote builder SSH key — for nix-daemon remote builds
    key-nixbuilder = {
      file = ../../secrets/ssh/key-nixbuilder.age;
      mode = "0400";
      owner = "root";
      group = "wheel";
    };

  };
}
