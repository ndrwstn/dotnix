# systems/common/secrets.nix
# Universal agenix identity setup for all machines.
# Secret payload declarations live with the selected user/platform/machine module.

{ ... }:

{
  # Common identity paths for all systems
  age.identityPaths = [
    "/etc/ssh/ssh_host_ed25519_key"
  ];

}
