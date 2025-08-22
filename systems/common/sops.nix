# systems/common/sops.nix
{ config, lib, pkgs, ... }:

lib.mkMerge [
  # Common sops configuration for NixOS systems only
  (lib.mkIf (!pkgs.stdenv.isDarwin) {
    sops = {
      # Default age key file location
      age.keyFile = "/var/lib/sops-nix/key.txt";

      # Default sops format
      defaultSopsFormat = "yaml";

      # Define secrets unconditionally - sops-nix handles missing keys at runtime
      secrets = {
        # "common/example" = {
        #   sopsFile = ./common.sops.yaml;
        #   key = "common.example_secret";
        # };

        # WiFi network password
        "wifi/home_network_psk" = {
          sopsFile = ./wifi.sops.yaml;
          key = "wifi.networks.0.psk";
        };
      };
    };
  })
]
