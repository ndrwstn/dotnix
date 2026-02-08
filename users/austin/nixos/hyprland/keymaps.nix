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
      "CTRL,Return,exec,${unstable.ghostty}/bin/ghostty --working-directory=\"$HOME\""

      # Application launcher
      "${mod},Space,exec,${pkgs.wofi}/bin/wofi --show drun"
      "${mod},B,exec,${pkgs.ungoogled-chromium}/bin/chromium"
      "${mod},P,exec,${pkgs._1password-gui}/bin/1password"
      "${mod},E,exec,${pkgs.xdg-utils}/bin/xdg-open $HOME"

      # Window management
      "${mod},Q,killactive,"
      "${mod},F,fullscreen,"
      "${mod},V,togglefloating,"

      # Session
      "${mod}+SHIFT,R,exec,hyprctl reload"
      "${mod}+SHIFT,E,exec,${pkgs.wlogout}/bin/wlogout"

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
      "${mod},S,togglesplit,"

      # Gaps
      "${mod},period,exec,hyprctl keyword general:gaps_in 10"
      "${mod},comma,exec,hyprctl keyword general:gaps_in 5"

      # Screenshot
      "${mod}+SHIFT,S,exec,${pkgs.grim}/bin/grim -g \"$(${pkgs.slurp}/bin/slurp)\" ~/Pictures/screenshot-$(date +%Y%m%d-%H%M%S).png"
      "${mod}+SHIFT,P,exec,${pkgs.grim}/bin/grim ~/Pictures/screenshot-$(date +%Y%m%d-%H%M%S).png"

      # Audio control
      ",XF86AudioRaiseVolume,exec,${pkgs.pulseaudio}/bin/pactl set-sink-volume @DEFAULT_SINK@ +5%"
      ",XF86AudioLowerVolume,exec,${pkgs.pulseaudio}/bin/pactl set-sink-volume @DEFAULT_SINK@ -5%"
      ",XF86AudioMute,exec,${pkgs.pulseaudio}/bin/pactl set-sink-mute @DEFAULT_SINK@ toggle"
      ",XF86AudioMicMute,exec,${pkgs.pulseaudio}/bin/pactl set-source-mute @DEFAULT_SOURCE@ toggle"
      ",XF86AudioPlay,exec,${pkgs.playerctl}/bin/playerctl play-pause"
      ",XF86AudioPause,exec,${pkgs.playerctl}/bin/playerctl pause"
      ",XF86AudioNext,exec,${pkgs.playerctl}/bin/playerctl next"
      ",XF86AudioPrev,exec,${pkgs.playerctl}/bin/playerctl previous"

      # Brightness control
      ",XF86MonBrightnessUp,exec,${pkgs.light}/bin/light -A 5"
      ",XF86MonBrightnessDown,exec,${pkgs.light}/bin/light -U 5"
    ];
  };

  wayland.windowManager.hyprland.extraConfig = ''
    bind=${mod},R,submap,resize

    submap=resize
    binde=,right,resizeactive,10 0
    binde=,left,resizeactive,-10 0
    binde=,up,resizeactive,0 -10
    binde=,down,resizeactive,0 10
    bind=,escape,submap,reset
    submap=reset
  '';
}
