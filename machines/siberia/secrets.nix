# machines/siberia/secrets.nix
{ ... }:

{
  # Siberia-specific agenix secrets configuration
  # TODO: Create age secrets for Siberia and configure them here
  # For now, this is a placeholder to allow the system to build

  # Configure agenix identity paths
  age.identityPaths = [
    "/etc/ssh/ssh_host_ed25519_key"
  ];
}
