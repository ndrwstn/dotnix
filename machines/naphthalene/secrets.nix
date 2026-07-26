# machines/naphthalene/secrets.nix
# LXC builder — agenix secrets for SSH identity and shared secrets.
{ config, pkgs, lib, ... }:

{
  # Use the SSH host key as the agenix identity (standard pattern)
  age.identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

  age.secrets = {
    # Machine SSH identity (private key deployed to /etc/ssh/)
    machine-naphthalene = {
      file = ../../secrets/ssh/machine-naphthalene.age;
      path = "/etc/ssh/ssh_host_ed25519_key";
      mode = "0400";
      owner = "root";
      group = "root";
    };
  };
}
