{ config
, pkgs
, unstable
, lib
, osConfig ? { }
, ...
}:
let
  hostName = lib.toLower (osConfig.networking.hostName or "");
  isSiberia = hostName == "siberia";
  shairportPackage = unstable.shairport-sync.override { enableAirplay2 = true; };
  shairportConfig = pkgs.writeText "shairport-sync-siberia.conf" ''
    general =
    {
      name = "Siberia";
      output_backend = "pulseaudio";
      mdns_backend = "avahi";

      // Let the iPhone control volume directly without being limited to
      // a percentage of the system volume. shairport-sync sets the stream
      // volume in PulseAudio, which PipeWire applies to the output.
      ignore_volume_control = "no";
    };
  '';
  waitForRuntimeDependencies = pkgs.writeShellScript "shairport-sync-wait-for-runtime" ''
    set -eu

    for _ in {1..60}; do
      if [ -S "''${XDG_RUNTIME_DIR}/pulse/native" ]; then
        break
      fi
      ${pkgs.coreutils}/bin/sleep 1
    done

    test -S "''${XDG_RUNTIME_DIR}/pulse/native"

    for _ in {1..30}; do
      if ${pkgs.systemd}/bin/systemctl is-active --quiet nqptp.service; then
        break
      fi
      ${pkgs.coreutils}/bin/sleep 1
    done

    ${pkgs.systemd}/bin/systemctl is-active --quiet nqptp.service
    test -r /dev/shm/nqptp
  '';
in
lib.mkIf isSiberia {
  home.packages = [ shairportPackage ];

  systemd.user.services.shairport-sync = {
    Unit = {
      Description = "Shairport Sync AirPlay receiver";
      Wants = [
        "pipewire.service"
        "pipewire-pulse.socket"
        "wireplumber.service"
      ];
      After = [
        "pipewire.service"
        "pipewire-pulse.socket"
        "wireplumber.service"
      ];
      PartOf = [ "graphical-session.target" ];
    };

    Service = {
      Type = "simple";
      ExecStartPre = waitForRuntimeDependencies;
      ExecStart = "${lib.getExe shairportPackage} -c ${shairportConfig}";
      Restart = "on-failure";
      RestartSec = "5s";
      Environment = [
        "PULSE_SERVER=unix:%t/pulse/native"
      ];
    };

    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
