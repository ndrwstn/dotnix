# Manual ClamAV tooling.  This feature intentionally does not enable a daemon.
{ config, autopkgs, ... }:
let
  dataDirectory = "${config.users.users.austin.home}/.local/share/clamav";
in
{
  environment.systemPackages = [ autopkgs.clamav ];

  environment.etc."clamav/certs/.keep".text = "";

  environment.etc."clamav/freshclam.conf".text = ''
    DatabaseDirectory ${dataDirectory}
    DatabaseMirror database.clamav.net
    Foreground yes
    Checks 0
    UpdateLogFile ${dataDirectory}/freshclam.log
    LogTime yes
    LogRotate yes
    LogFileMaxSize 2M
    TestDatabases yes
    ScriptedUpdates yes
    ConnectTimeout 60
    ReceiveTimeout 120
    MaxAttempts 3
    Bytecode yes
  '';
}
