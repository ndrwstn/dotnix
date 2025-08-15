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
  # Only enable if NetworkManager is not enabled to avoid conflicts
  networking.wireless = lib.mkIf (!config.networking.networkmanager.enable) {
    enable = lib.mkDefault true;
    networks = {
      "Pretty Fly for a Wi-Fi".passwordFile = config.sops.secrets."wifi/home_network_psk".path;
    };
  };
}
