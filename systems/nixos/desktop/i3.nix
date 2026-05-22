# systems/nixos/desktop/i3.nix
# i3 window manager system configuration.
{ config
, pkgs
, lib
, ...
}:

lib.mkIf (builtins.elem "i3" config._astn.machine.windowManagers) {
  services.xserver.windowManager.i3 = {
    enable = true;
    extraPackages = with pkgs; [
      dmenu
      i3status
    ];
  };
}
