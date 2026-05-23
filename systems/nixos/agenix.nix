# systems/nixos/agenix.nix
{ inputs, pkgs, ... }:

{
  # Import agenix module
  imports = [
    inputs.agenix.nixosModules.default
  ];

  # Add agenix package to system packages
  environment.systemPackages = [
    inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  # Configure agenix
  age = {
    secretsDir = "/run/agenix";
    secretsMountPoint = "/run/agenix.d";

  };
}
