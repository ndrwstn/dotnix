{ pkgs, lib, ... }:

let
  onePasswordGui = lib.getExe pkgs._1password-gui;
in
{
  systemd.user.services._1password = {
    Unit = {
      Description = "1Password";
      PartOf = [ "graphical-session.target" ];
    };

    Service = {
      ExecStart = "${onePasswordGui} --silent";
      Restart = "on-failure";
      Type = "simple";
    };

    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
