# systems/common/sops.nix
{ config, lib, pkgs, ... }:

{
  # Common sops configuration for all systems
  sops = {
    # Default age key file location
    age.keyFile = "/var/lib/sops-nix/key.txt";

    # Default sops format
    defaultSopsFormat = "yaml";

    # Common secrets
    secrets = {
      "common/example" = {
        sopsFile = ./common.sops.yaml;
        key = "common.example_secret";
      };

      # WiFi network password
      "wifi/home_network_psk" = {
        sopsFile = ./wifi.sops.yaml;
        key = "wifi.networks.0.psk";
      };
    };
  };

  # Declarative NetworkManager WiFi configuration
  networking.networkmanager.ensureProfiles = {
    profiles = {
      "Pretty Fly for a Wi-Fi" = {
        connection = {
          id = "Pretty Fly for a Wi-Fi";
          type = "wifi";
          autoconnect = true;
        };
        wifi = {
          mode = "infrastructure";
          ssid = "Pretty Fly for a Wi-Fi";
        };
        wifi-security = {
          auth-alg = "open";
          key-mgmt = "wpa-psk";
          psk-file = config.sops.secrets."wifi/home_network_psk".path;
        };
        ipv4.method = "auto";
        ipv6.method = "auto";
      };
    };
  };
}
