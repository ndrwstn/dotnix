# users/austin/secrets.nix
# Secrets consumed by Austin's system and Home Manager configuration.
{ config, pkgs, lib, ... }:

let
  workstation = builtins.elem (config._astn.machine.role or "") [ "desktop" "laptop" ];
in
{
  age.secrets = lib.mkIf workstation {
    syncthing = {
      file = ../../secrets/syncthing/config-shared.age;
      mode = "0400";
      owner = "austin";
      group = if pkgs.stdenv.isDarwin then "staff" else "users";
    };

    atuin = {
      file = ../../secrets/atuin.age;
      mode = "0400";
      owner = "austin";
      group = if pkgs.stdenv.isDarwin then "staff" else "users";
    };

    general = {
      file = ../../secrets/general.age;
      mode = "0400";
      owner = "austin";
      group = if pkgs.stdenv.isDarwin then "staff" else "users";
    };
  };
}
