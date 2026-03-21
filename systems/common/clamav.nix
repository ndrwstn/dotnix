# systems/common/clamav.nix
# ClamAV antivirus configuration - manual usage only (no daemon)
{ config
, pkgs
, lib
, ...
}: {
  # Install clamav package
  environment.systemPackages = with pkgs; [
    clamav
  ];

  # Create freshclam configuration file
  environment.etc."clamav/freshclam.conf".text = ''
    DatabaseDirectory /Users/austin/.local/share/clamav
    DatabaseMirror database.clamav.net
    Foreground yes
    Checks 0
    UpdateLogFile /Users/austin/.local/share/clamav/freshclam.log
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
