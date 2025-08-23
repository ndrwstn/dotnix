# users/austin/syncthing.nix
{ pkgs, ... }:

{
  services.syncthing = {
    enable = true;

    # GUI settings
    guiAddress = "127.0.0.1:8384"; # Local-only access

    # For now, disable cert/key on Darwin until we set up manual secret management
    # On NixOS, these will be provided by the agenix module
    cert = if pkgs.stdenv.isLinux then "/run/agenix/syncthing-silver-cert" else null;
    key = if pkgs.stdenv.isLinux then "/run/agenix/syncthing-silver-key" else null;
  };
}
# vim: set tabstop=2 softtabstop=2 shiftwidth=2 expandtab
