# users/austin/nixos/vicinae.nix
# Vicinae launcher configuration (Raycast-like for Linux)
{ config
, lib
, osConfig ? { }
, ...
}:
let
  windowManagers = osConfig._astn.machine.windowManagers or [ ];
  hasI3 = builtins.elem "i3" windowManagers;
in
{
  services.vicinae = {
    enable = true;
    systemd = {
      enable = true;
      environment = {
        PATH = lib.concatStringsSep ":" [
          "/run/wrappers/bin"
          "/run/current-system/sw/bin"
          "${config.home.profileDirectory}/bin"
          "${config.home.homeDirectory}/.nix-profile/bin"
        ];
        TMUX_TMPDIR = "%t";
        XDG_DATA_DIRS = lib.concatStringsSep ":" [
          "${config.home.profileDirectory}/share"
          "${config.home.homeDirectory}/.nix-profile/share"
          "/run/current-system/sw/share"
        ];
        XDG_RUNTIME_DIR = "%t";
      } // lib.optionalAttrs hasI3 {
        DESKTOP_SESSION = "i3";
        XDG_CURRENT_DESKTOP = "i3";
      };
    };
  };

  systemd.user.services.vicinae.Unit.Requires = lib.mkAfter [ "dbus.socket" ];
}
