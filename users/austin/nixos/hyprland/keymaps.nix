# users/austin/nixos/hyprland/keymaps.nix
# Hyprland keybindings configuration
{ pkgs, unstable, ... }:

let
  mod = "SUPER";
  cliphistMenu = pkgs.writeShellScript "cliphist-menu" ''
    set -eu

    selection="$(${pkgs.cliphist}/bin/cliphist list | ${pkgs.wofi}/bin/wofi --dmenu --prompt 'Clipboard')"

    if [ -n "''${selection}" ]; then
      printf '%s' "''${selection}" | ${pkgs.cliphist}/bin/cliphist decode | ${pkgs.wl-clipboard}/bin/wl-copy
    fi
  '';
in
{
  wayland.windowManager.hyprland.settings = {
    bind = [
      # Terminal
      "${mod},Return,exec,${unstable.ghostty}/bin/ghostty --working-directory=\"$HOME\""

      # Application launcher
      "${mod},Space,exec,${pkgs.wofi}/bin/wofi --show drun"
      "${mod},B,exec,${pkgs.ungoogled-chromium}/bin/chromium"
      "${mod},C,exec,${cliphistMenu}"
      "${mod},P,exec,${pkgs._1password-gui}/bin/1password"
      "${mod},E,exec,${pkgs.xdg-utils}/bin/xdg-open $HOME"
      "${mod},N,exec,${pkgs.networkmanagerapplet}/bin/nm-connection-editor"
      "${mod},M,exec,${pkgs.pavucontrol}/bin/pavucontrol"

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

      # Audio and media control
      ",XF86AudioMute,exec,${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
      ",XF86AudioMicMute,exec,${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
      ",XF86AudioPlay,exec,${pkgs.playerctl}/bin/playerctl play-pause"
      ",XF86AudioPause,exec,${pkgs.playerctl}/bin/playerctl pause"
      ",XF86AudioStop,exec,${pkgs.playerctl}/bin/playerctl stop"
      ",XF86AudioNext,exec,${pkgs.playerctl}/bin/playerctl next"
      ",XF86AudioPrev,exec,${pkgs.playerctl}/bin/playerctl previous"
      ",XF86AudioForward,exec,${pkgs.playerctl}/bin/playerctl position 5+"
      ",XF86AudioRewind,exec,${pkgs.playerctl}/bin/playerctl position 5-"

      # Common laptop helper keys
      ",XF86Explorer,exec,${pkgs.xdg-utils}/bin/xdg-open $HOME"
      ",XF86Launch1,exec,${pkgs.wofi}/bin/wofi --show drun"
      ",XF86Launch2,exec,${pkgs.networkmanagerapplet}/bin/nm-connection-editor"
    ];

    binde = [
      ",XF86AudioRaiseVolume,exec,${pkgs.wireplumber}/bin/wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+"
      ",XF86AudioLowerVolume,exec,${pkgs.wireplumber}/bin/wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%-"
      ",XF86MonBrightnessUp,exec,${pkgs.brightnessctl}/bin/brightnessctl -d acpi_video0 set 5%+"
      ",XF86MonBrightnessDown,exec,${pkgs.brightnessctl}/bin/brightnessctl -d acpi_video0 set 5%-"
      ",XF86KbdBrightnessUp,exec,${pkgs.brightnessctl}/bin/brightnessctl -d smc::kbd_backlight set 10%+"
      ",XF86KbdBrightnessDown,exec,${pkgs.brightnessctl}/bin/brightnessctl -d smc::kbd_backlight set 10%-"
    ];

    bindm = [
      "${mod},mouse:272,movewindow"
      "${mod},mouse:273,resizewindow"
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
