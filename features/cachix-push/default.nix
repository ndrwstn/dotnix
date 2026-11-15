{ config, lib, pkgs, ... }:

let
  secretPath = "/run/agenix/cachix";
in
{
  age.secrets.cachix = {
    file = ../../secrets/cachix.age;
    mode = "0400";
  };

  systemd.services.cachix-watch-store = {
    description = "Push newly built Nix store paths to Cachix";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    path = [ pkgs.bash pkgs.cachix pkgs.jq ];
    serviceConfig = {
      Type = "simple";
      Restart = "on-failure";
      RestartSec = 10;
      ExecStart = pkgs.writeShellScript "cachix-watch-store" ''
        set -eu

        while [ ! -r ${secretPath} ]; do
          sleep 1
        done

        export CACHIX_AUTH_TOKEN="$(jq -er '.authToken' ${secretPath})"
        exec cachix watch-store ndrwstn-dotnix
      '';
    };
  };
}
