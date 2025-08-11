# machines/monaco/secrets.nix
{ config, lib, pkgs, ... }:

{
  # Define the secrets
  sops.secrets = {
    # Wi-Fi configuration
    "wifi/home_network_psk" = {
      sopsFile = ../../secrets/machines/monaco/wifi.yaml;
      key = "wifi.networks.0.psk";
    };
    "wifi/work_network_psk" = {
      sopsFile = ../../secrets/machines/monaco/wifi.yaml;
      key = "wifi.networks.1.psk";
    };
  };

  # Example of using the secrets
  networking.wireless = {
    enable = lib.mkDefault true;
    networks = {
      "Home_Network".passwordFile = config.sops.secrets."wifi/home_network_psk".path;
      "Work_Network".passwordFile = config.sops.secrets."wifi/work_network_psk".path;
    };
  };
}