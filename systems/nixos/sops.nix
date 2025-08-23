# systems/nixos/sops.nix
{ config, lib, pkgs, ... }:

{
  sops = {
    # Default age key file location
    age.keyFile = "/var/lib/sops-nix/key.txt";

    # Default sops format
    defaultSopsFormat = "yaml";

    # Don't validate sops files during build - validation happens at runtime
    validateSopsFiles = false;

    # Define secrets unconditionally - sops-nix handles missing keys at runtime
    secrets = {
      # WiFi network credentials
      "wifi/home/psk" = {
        sopsFile = ../common/wifi.sops.yaml;
      };
      "wifi/home/ssid" = {
        sopsFile = ../common/wifi.sops.yaml;
      };
    };
  };
}
