# users/austin/nixos/vicinae.nix
# Vicinae launcher configuration (Raycast-like for Linux)
{ config
, pkgs
, lib
, osConfig ? { }
, vicinae
, ...
}:
let
  windowManagers = osConfig._astn.machine.windowManagers or [ ];
  hasI3 = builtins.elem "i3" windowManagers;
  # Numen's C++ parser can exhaust the memory of Silver's remote builder when
  # Ninja compiles all translation units concurrently. Keep this override
  # local to the Vicinae dependency rather than reducing parallelism globally.
  numen = vicinae.inputs.numen.packages.${pkgs.system}.default.overrideAttrs (old: {
    enableParallelBuilding = false;
    cmakeFlags = old.cmakeFlags ++ [ "-DCMAKE_BUILD_PARALLEL_LEVEL=1" ];
  });
in
{
  programs.vicinae = {
    enable = true;
    package = vicinae.packages.${pkgs.system}.default.override { inherit numen; };
    # Vicinae shows "uwsm app --" as a default/placeholder launch prefix, but
    # empty/unset still allows auto-detection of uwsm. Set a non-empty no-op
    # prefix to force direct app launching.
    #
    # We are not enabling uwsm (Universal Wayland Session Manager) because:
    # - Hyprland systems already use Home Manager's systemd integration
    # - i3/X11 should not use a Wayland session manager
    # - The added abstraction does not measurably improve performance here
    # See discussion in PR/commit history for full rationale.
    settings.providers.applications.preferences.launchPrefix =
      "${pkgs.coreutils}/bin/env --";

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

  # Restart vicinae after home-manager activation to pick up updated
  # package paths (XDG .desktop files and PATH binaries). Without this,
  # vicinae's in-memory app database may reference stale Nix store paths
  # when packages (e.g., from nixautopkgs) are updated.
  home.activation.restartVicinae = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    # Restart vicinae after activation to pick up updated package paths.
    # If the user systemd manager is not available (e.g. at boot before
    # user session starts), skip without failing — other activation
    # entries (sshFilePermissions) must still run.
    ${pkgs.systemd}/bin/systemctl --user try-restart vicinae || true
  '';
}
