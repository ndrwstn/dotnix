# systems/nixos/sops.nix
{ config, lib, pkgs, ... }:

{
  # NixOS-specific sops configuration
  sops = {
    # Use the default age key location
    age.keyFile = "/var/lib/sops-nix/key.txt";

    # Generate an age key if one doesn't exist
    age.generateKey = true;
  };

  # Add sops-related packages to the system
  environment.systemPackages = with pkgs; [
    sops
    age
  ];

  # Declarative NetworkManager WiFi configuration (NixOS only)
  # Only configure WiFi if the WiFi secret is available
  networking.networkmanager.ensureProfiles = lib.mkIf
    (config ? sops.secrets."wifi/home_network_psk")
    {
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
