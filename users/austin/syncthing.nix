# users/austin/syncthing.nix
{ config, pkgs, lib, systemSecrets ? { }, ... }:

{
  services.syncthing = {
    enable = true;

    # GUI settings
    guiAddress = "127.0.0.1:8384"; # Local-only access

    # Use system secrets when available (NixOS)
    # On Darwin, systemSecrets will be empty {} so these evaluate to null
    cert = systemSecrets."syncthing/cert".path or null;
    key = systemSecrets."syncthing/key".path or null;
  };
}
# vim: set tabstop=2 softtabstop=2 shiftwidth=2 expandtab
