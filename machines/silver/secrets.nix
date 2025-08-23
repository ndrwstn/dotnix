# machines/silver/secrets.nix
{ ... }:

{
  # Silver-specific agenix secrets configuration
  age.secrets = {
    # Syncthing secrets for Silver
    syncthing-silver-device-id = {
      file = ../../secrets/syncthing-silver-device-id.age;
      mode = "0400";
      owner = "austin";
      group = "users";
    };
    syncthing-silver-cert = {
      file = ../../secrets/syncthing-silver-cert.age;
      mode = "0400";
      owner = "austin";
      group = "users";
    };
    syncthing-silver-key = {
      file = ../../secrets/syncthing-silver-key.age;
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
