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

    # NEW: Shared syncthing configuration (all machines can decrypt)
    syncthing = {
      file = ../../secrets/syncthing.age;
      mode = "0400";
      owner = "austin";
      group = "users";
    };
  };

  # Configure agenix identity paths
  age.identityPaths = [
    "/etc/ssh/ssh_host_ed25519_key"
  ];
}
