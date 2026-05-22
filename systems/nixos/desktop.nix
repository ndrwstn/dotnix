# systems/nixos/desktop.nix
# NixOS graphical session selection based on _astn.machine.windowManagers.
{ config
, pkgs
, lib
, ...
}:

let
  windowManagers = config._astn.machine.windowManagers;
  hasWindowManager = name: builtins.elem name windowManagers;

  hasGraphicalSession = windowManagers != [ ];
  hasGnome = hasWindowManager "gnome";
  hasHyprland = hasWindowManager "hyprland";
  hasI3 = hasWindowManager "i3";

  useGdm = hasGnome || hasHyprland;
  useLightdm = !useGdm && hasI3;
in
lib.mkMerge [
  (lib.mkIf hasGraphicalSession {
    services.xserver = {
      enable = true;

      xkb = {
        layout = "us";
        variant = "";
      };
    };

    hardware.graphics.enable = true;
    security.polkit.enable = true;
  })

  (lib.mkIf useGdm {
    services.displayManager.gdm.enable = true;
  })

  (lib.mkIf useLightdm {
    services.xserver.displayManager.lightdm.enable = true;
  })

  (lib.mkIf hasGnome {
    services.desktopManager.gnome.enable = true;

    # Exclude Seahorse to prevent SSH_ASKPASS interference.
    environment.gnome.excludePackages = [ pkgs.seahorse ];
  })

  (lib.mkIf hasI3 {
    services.xserver.windowManager.i3 = {
      enable = true;
      extraPackages = with pkgs; [
        dmenu
        i3status
      ];
    };
  })
]
