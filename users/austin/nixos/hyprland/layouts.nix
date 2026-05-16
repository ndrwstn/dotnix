# users/austin/nixos/hyprland/layouts.nix
# Hyprland 0.55+ Lua custom layouts.
{ ... }:

{
  xdg.configFile."hypr/layouts/workspace-grid-3x2.lua".source =
    ./layouts/workspace-grid-3x2.lua;

  # Hyprland 0.55 loads either hyprland.lua or hyprland.conf, not both. Home
  # Manager 25.11 still generates only hyprland.conf, so this module installs
  # the layout implementation without creating a hyprland.lua that would shadow
  # the existing generated config. Once Home Manager Lua configType support is
  # available here, load this layout from hyprland.lua with:
  #
  #   require("layouts/workspace-grid-3x2")
  #   hl.workspace_rule({ workspace = "1", layout = "lua:workspace-grid-3x2" })
}
