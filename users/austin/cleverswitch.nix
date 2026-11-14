# users/austin/cleverswitch.nix
{ config
, autopkgs
, hostName
, lib
, pkgs
, ...
}:
let
  enabled = builtins.elem hostName [ "monaco" "silver" ];
  cleverswitch = autopkgs.cleverswitch;
  executable = lib.getExe cleverswitch;
in
{
  home.packages = lib.mkIf enabled [ cleverswitch ];

  systemd.user.services.cleverswitch = lib.mkIf (enabled && pkgs.stdenv.isLinux) {
    Unit = {
      Description = "Synchronize Logitech Easy-Switch host changes";
      After = [ "graphical-session.target" ];
      Wants = [ "graphical-session.target" ];
    };

    Service = {
      Type = "simple";
      ExecStart = executable;
      Restart = "on-failure";
      RestartSec = "10s";
      Environment = [ "HOME=${config.home.homeDirectory}" ];
    };

    Install = {
      WantedBy = [ "default.target" ];
    };
  };

  launchd.agents.cleverswitch = lib.mkIf (enabled && pkgs.stdenv.isDarwin) {
    enable = true;
    config = {
      ProgramArguments = [ executable ];
      EnvironmentVariables = {
        HOME = config.home.homeDirectory;
      };
      RunAtLoad = true;
      KeepAlive = {
        SuccessfulExit = false;
      };
      StandardOutPath = "/tmp/cleverswitch.launchd.log";
      StandardErrorPath = "/tmp/cleverswitch.launchd.error.log";
    };
  };
}
