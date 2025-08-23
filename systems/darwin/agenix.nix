# systems/darwin/agenix.nix
{ inputs, pkgs, ... }:

{
  # Add agenix package to system packages
  environment.systemPackages = [
    inputs.agenix.packages.${pkgs.system}.default
  ];

  # For Darwin, we'll handle secrets manually since agenix doesn't have native Darwin support
  # The secrets will be available in /var/lib/age/ and managed by the agenix CLI
}
