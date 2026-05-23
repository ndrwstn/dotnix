{ config, lib, osConfig ? { }, ... }:
let
  windowManagers = osConfig._astn.machine.windowManagers or [ ];
  hasHyprland = builtins.elem "hyprland" windowManagers;
in
{
  xdg.configFile."oh-my-posh/ohmyposh-default.json".source =
    ../shell/ohmyposh-default.json;

  # TODO(2026-05-23): This consumer-side matugen guard is a hack.
  # Wallpaper-generated theming should be centralized/scoped to a single
  # Hyprland/theming module instead of scattered across app configs.
  programs.oh-my-posh.configFile = lib.mkIf hasHyprland
    "${config.xdg.configHome}/oh-my-posh/wallpaper.json";
}
