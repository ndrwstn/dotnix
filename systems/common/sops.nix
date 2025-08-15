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

      # WiFi network passwords
      "wifi/home_network_psk" = {
        sopsFile = ./wifi.sops.yaml;
        key = "wifi.networks.0.psk";
      };
      "wifi/work_network_psk" = {
        sopsFile = ./wifi.sops.yaml;
        key = "wifi.networks.1.psk";
      };
    };
  };

  # WiFi configuration using the secrets
  networking.wireless = {
    enable = lib.mkDefault true;
    networks = {
      "Home_Network".passwordFile = config.sops.secrets."wifi/home_network_psk".path;
      "Work_Network".passwordFile = config.sops.secrets."wifi/work_network_psk".path;
    };
  };
}
