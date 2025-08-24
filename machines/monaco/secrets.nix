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

  # Configure agenix identity paths for Monaco
  age.identityPaths = [
    "/etc/ssh/ssh_host_ed25519_key"
    "/etc/ssh/ssh_host_rsa_key"
  ];
}
