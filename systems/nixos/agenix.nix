# systems/nixos/agenix.nix
{ inputs, ... }:

{
  # Import agenix module
  imports = [
    inputs.agenix.nixosModules.default
  ];

  # Add agenix package to system packages
  environment.systemPackages = [
    inputs.agenix.packages.${builtins.currentSystem}.default
  ];

  # Configure agenix
  age = {
    # Secrets directory
    secrets = {
      # WiFi secrets
      wifi-home-ssid = {
        file = ../../secrets/wifi-home-ssid.age;
        mode = "0400";
        owner = "austin";
        group = "users";
      };
      wifi-home-psk = {
        file = ../../secrets/wifi-home-psk.age;
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
