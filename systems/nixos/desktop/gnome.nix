# systems/nixos/desktop/gnome.nix
# GNOME desktop environment configuration.
{ config
, pkgs
, lib
, ...
}:

lib.mkIf (builtins.elem "gnome" config._astn.machine.windowManagers) {
  services.desktopManager.gnome.enable = true;

  # Exclude Seahorse to prevent SSH_ASKPASS interference.
  environment.gnome.excludePackages = [ pkgs.seahorse ];
}
