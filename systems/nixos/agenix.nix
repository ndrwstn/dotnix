# systems/nixos/agenix.nix
{ inputs, pkgs, ... }:

{
  # Import agenix module
  imports = [
    inputs.agenix.nixosModules.default
  ];

  # Add agenix package to system packages
  environment.systemPackages = [
    inputs.agenix.packages.${pkgs.system}.default
  ];

  # Configure agenix
  age = {
    secretsDir = "/run/agenix";
    secretsMountPoint = "/run/agenix.d";

    # Secrets directory
    secrets = {
      # WiFi secrets (consolidated JSON)
      wifi-home = {
        file = ../../secrets/wifi-home.age;
        mode = "0400";
        owner = "austin";
        group = "users";
      };
    };

    # Identity files for decryption
    identityPaths = [
      "/etc/ssh/ssh_host_ed25519_key"
    ];
  };
}
