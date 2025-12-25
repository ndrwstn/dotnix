# users/austin/nixos/hyprland/keymaps.nix
# Hyprland keybindings configuration
{ pkgs, unstable, ... }:

let
  mod = "SUPER";
in
{
  wayland.windowManager.hyprland.settings = {
    bind = [
      # Terminal
      "${mod},Return,exec,${unstable.ghostty}/bin/ghostty"

      # Application launcher
      "${mod},Space,exec,${pkgs.wofi}/bin/wofi --show drun"

      # Window management
      "${mod},Q,killactive,"
      "${mod},F,fullscreen,"

      # Workspace navigation
      "${mod},1,workspace,1"
      "${mod},2,workspace,2"
      "${mod},3,workspace,3"
      "${mod},4,workspace,4"
      "${mod},5,workspace,5"
      "${mod},6,workspace,6"
      "${mod},7,workspace,7"
      "${mod},8,workspace,8"
      "${mod},9,workspace,9"
      "${mod},0,workspace,10"

      # Move window to workspace
      "${mod}+SHIFT,1,movetoworkspace,1"
      "${mod}+SHIFT,2,movetoworkspace,2"
      "${mod}+SHIFT,3,movetoworkspace,3"
      "${mod}+SHIFT,4,movetoworkspace,4"
      "${mod}+SHIFT,5,movetoworkspace,5"
      "${mod}+SHIFT,6,movetoworkspace,6"
      "${mod}+SHIFT,7,movetoworkspace,7"
      "${mod}+SHIFT,8,movetoworkspace,8"
      "${mod}+SHIFT,9,movetoworkspace,9"
      "${mod}+SHIFT,0,movetoworkspace,10"

      # Window navigation
      "${mod},H,movefocus,l"
      "${mod},J,movefocus,d"
      "${mod},K,movefocus,u"
      "${mod},L,movefocus,r"

      # Move windows
      "${mod}+SHIFT,H,movewindow,l"
      "${mod}+SHIFT,J,movewindow,d"
      "${mod}+SHIFT,K,movewindow,u"
      "${mod}+SHIFT,L,movewindow,r"

      # Layout
      "${mod},E,layoutmsg,toggleorientation"
      "${mod},S,togglesplit,"

      # Gaps
      "${mod},period,exec,hyprctl keyword general:gaps_in 10"
      "${mod},comma,exec,hyprctl keyword general:gaps_in 5"

      # Screenshot
      "${mod},P,exec,${pkgs.grim}/bin/grim -g \"$(${pkgs.slurp}/bin/slurp)\" ~/Pictures/screenshot-$(date +%Y%m%d-%H%M%S).png"
      "${mod}+SHIFT,P,exec,${pkgs.grim}/bin/grim ~/Pictures/screenshot-$(date +%Y%m%d-%H%M%S).png"

      # Audio control
      ",XF86AudioRaiseVolume,exec,${pkgs.pulseaudio}/bin/pactl set-sink-volume @DEFAULT_SINK@ +5%"
      ",XF86AudioLowerVolume,exec,${pkgs.pulseaudio}/bin/pactl set-sink-volume @DEFAULT_SINK@ -5%"
      ",XF86AudioMute,exec,${pkgs.pulseaudio}/bin/pactl set-sink-mute @DEFAULT_SINK@ toggle"

      # Brightness control
      ",XF86MonBrightnessUp,exec,${pkgs.light}/bin/light -A 5"
      ",XF86MonBrightnessDown,exec,${pkgs.light}/bin/light -U 5"
    ];
  };
}
