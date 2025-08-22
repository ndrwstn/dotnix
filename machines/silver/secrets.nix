# machines/silver/secrets.nix
{ config, lib, pkgs, ... }:

{
  # Import syncthing secrets
  sops.secrets = {
    "syncthing/device_id" = {
      sopsFile = ./syncthing.sops.yaml;
      key = "syncthing.device_id";
      owner = "austin";
      group = "users";
      mode = "0400";
    };
    "syncthing/cert" = {
      sopsFile = ./syncthing.sops.yaml;
      key = "syncthing.cert";
      owner = "austin";
      group = "users";
      mode = "0400";
    };
    "syncthing/key" = {
      sopsFile = ./syncthing.sops.yaml;
      key = "syncthing.key";
      owner = "austin";
      group = "users";
      mode = "0400";
    };
  };
}
