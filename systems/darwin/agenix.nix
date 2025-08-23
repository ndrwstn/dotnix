# systems/darwin/agenix.nix
{ inputs, pkgs, ... }:

{
  # Import agenix Darwin module for native secret management
  imports = [
    inputs.agenix.darwinModules.default
  ];

  # Add agenix package to system packages for CLI tools
  environment.systemPackages = [
    inputs.agenix.packages.${pkgs.system}.default
  ];

  # Configure agenix identity paths for Darwin
  age.identityPaths = [
    "/etc/ssh/ssh_host_ed25519_key"
    "/etc/ssh/ssh_host_rsa_key"
  ];
}
