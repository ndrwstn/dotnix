# systems/nixos/desktop/default.nix
# Shared graphical-session plumbing and display-manager policy.
{ config
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
{
  imports = [
    ./gnome.nix
    ./hyprland.nix
    ./i3.nix
  ];

  config = lib.mkMerge [
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
      services.gvfs.enable = true;
      services.xserver.libinput.naturalScrolling = true;
    })

    (lib.mkIf useGdm {
      services.displayManager.gdm.enable = true;
    })

    (lib.mkIf useLightdm {
      services.xserver.displayManager.lightdm.enable = true;
    })
  ];
}
