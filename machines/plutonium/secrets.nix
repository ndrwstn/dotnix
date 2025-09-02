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

    # Shared syncthing configuration (all machines can decrypt)
    syncthing = {
      file = ../../secrets/syncthing.age;
      mode = "0400";
      owner = "austin";
      group = "staff";
    };
  };

  # Configure agenix identity paths for Plutonium
  age.identityPaths = [
    "/etc/ssh/ssh_host_ed25519_key"
    "/etc/ssh/ssh_host_rsa_key"
  ];
}
