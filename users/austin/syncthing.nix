# users/austin/syncthing.nix
{ config, pkgs, lib, ... }:

{
  services.syncthing = {
    enable = true;

    # GUI settings
    guiAddress = "127.0.0.1:8384"; # Local-only access

    # Platform-specific certificate and key configuration
    # For NixOS: secrets are managed at system level and passed through
    # For Darwin: secrets should be configured at machine level via home-manager sops
    cert = lib.mkIf (config.sops.secrets ? "syncthing/cert")
      config.sops.secrets."syncthing/cert".path;

    key = lib.mkIf (config.sops.secrets ? "syncthing/key")
      config.sops.secrets."syncthing/key".path;
  };
}
# vim: set tabstop=2 softtabstop=2 shiftwidth=2 expandtab
