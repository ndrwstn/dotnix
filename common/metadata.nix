# Typed machine metadata. Values are supplied by the flake's metadata module.
{ config, lib, ... }:
{
  options._astn = lib.mkOption {
    type = lib.types.submodule {
      options.machine = {
        system = lib.mkOption {
          type = lib.types.enum [ "x86_64-linux" "aarch64-darwin" "x86_64-darwin" ];
          default = "x86_64-linux";
        };
        role = lib.mkOption {
          type = lib.types.enum [ "desktop" "laptop" "virtual" "server" ];
          default = "desktop";
        };
        features = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
        };
        users = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
        };
        windowManagers = lib.mkOption {
          type = lib.types.listOf (lib.types.enum [ "gnome" "hyprland" "i3" ]);
          default = [ "gnome" "hyprland" ];
        };
      };
      options.presets = {
        gui.enable = lib.mkOption {
          type = lib.types.bool;
          default = config._astn.machine.windowManagers != [ ];
        };
        graphics.enable = lib.mkEnableOption "graphics application preset";
        maker.enable = lib.mkEnableOption "CAD/maker application preset";
        recording.enable = lib.mkEnableOption "recording application preset";
        office.enable = lib.mkEnableOption "office application preset";
        radio.enable = lib.mkEnableOption "radio/SDR application and hardware preset";
      };
    };
    default = { };
  };
}
