# Reusable OpenCode v2 server feature for NixOS guests.
{ config, lib, pkgs, opencode, ... }:

{
  config = lib.mkIf pkgs.stdenv.isLinux {
    users.groups.projects = { };
    users.users.opencode = {
      description = "opencode server";
      isSystemUser = true;
      group = "projects";
      home = "/var/lib/opencode";
      createHome = true;
    };

    environment.systemPackages = with pkgs; [
      opencode
      fd
      git
      jq
      ripgrep
      sqlite
      tmux
    ];

    # OpenCode is distributed as a dynamically linked runtime by nixautopkgs.
    programs.nix-ld = {
      enable = true;
      libraries = with pkgs; [
        acl
        attr
        bzip2
        curl
        libssh
        libxml2
        openssl
        stdenv.cc.cc
        util-linux
        xz
        zlib
        zstd
      ];
    };

    networking.firewall.allowedTCPPorts = [ 4096 ];

    systemd.services.opencode-serve = {
      description = "OpenCode v2 HTTP server";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      serviceConfig = {
        User = "opencode";
        Group = "projects";
        WorkingDirectory = "/projects";
        Environment = [
          "HOME=/var/lib/opencode"
          "XDG_CONFIG_HOME=/var/lib/opencode/.config"
          "XDG_DATA_HOME=/var/lib/opencode/.local/share"
          "XDG_STATE_HOME=/var/lib/opencode/.local/state"
        ];
        ExecStart = "${opencode}/bin/opencode serve --service --hostname 0.0.0.0 --port 4096";
        Restart = "on-failure";
        StateDirectory = "opencode";
        StateDirectoryMode = "0750";
        ReadWritePaths = [ "/projects" "/var/lib/opencode" ];
      };
    };

    systemd.services.opencode-sqlite-maintenance = {
      description = "Maintain opencode SQLite databases";
      serviceConfig = {
        Type = "oneshot";
        User = "opencode";
        Group = "projects";
        ExecStart = pkgs.writeShellScript "opencode-sqlite-maintenance" ''
          set -eu
          ${pkgs.findutils}/bin/find /var/lib/opencode -type f \( -name '*.db' -o -name '*.sqlite' -o -name '*.sqlite3' \) \
            -exec ${pkgs.sqlite}/bin/sqlite3 '{}' 'PRAGMA optimize;' \;
        '';
      };
    };

    systemd.timers.opencode-sqlite-maintenance = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "weekly";
        Persistent = true;
        Unit = "opencode-sqlite-maintenance.service";
      };
    };
  };
}
