# systems/common/sops.nix
{ config, lib, pkgs, ... }:

{
  # Common sops configuration for all systems
  sops = {
    # Default age key file location
    age.keyFile = "/var/lib/sops-nix/key.txt";

    # Default sops format
    defaultSopsFormat = "yaml";

    # Example common secrets
    secrets = {
      "common/example" = {
        sopsFile = ./common.sops.yaml;
        key = "common.example_secret";
      };
    };
  };
}
