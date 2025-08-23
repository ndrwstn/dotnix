# machines/monaco/secrets.nix
{ ... }:

{
  # Monaco-specific agenix secrets configuration
  age.secrets = {
    # Syncthing secrets for Monaco
    syncthing-monaco-device-id = {
      file = ../../secrets/syncthing-monaco-device-id.age;
      mode = "0400";
      owner = "austin";
      group = "staff";
    };
    syncthing-monaco-cert = {
      file = ../../secrets/syncthing-monaco-cert.age;
      mode = "0400";
      owner = "austin";
      group = "staff";
    };
    syncthing-monaco-key = {
      file = ../../secrets/syncthing-monaco-key.age;
      mode = "0400";
      owner = "austin";
      group = "staff";
    };
  };

  # Configure agenix identity paths for Monaco
  age.identityPaths = [
    "/etc/ssh/ssh_host_ed25519_key"
    "/etc/ssh/ssh_host_rsa_key"
  ];
}
