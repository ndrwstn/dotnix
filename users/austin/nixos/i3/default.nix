# users/austin/nixos/i3/default.nix
# Lightweight i3 configuration that mirrors the core Hyprland workflow.
{ config
, pkgs
, lib
, unstable
, ...
}:

let
  mod = "Mod4";
  screenshotDir = "${config.home.homeDirectory}/Pictures";
  i3SessionEnvironmentScript = pkgs.writeShellScript "i3-session-environment" ''
    ${pkgs.dbus}/bin/dbus-update-activation-environment --systemd \
      DISPLAY \
      XAUTHORITY \
      XDG_CURRENT_DESKTOP \
      DESKTOP_SESSION \
      PATH \
      XDG_DATA_DIRS || true
    ${pkgs.systemd}/bin/systemctl --user import-environment \
      DISPLAY \
      XAUTHORITY \
      XDG_CURRENT_DESKTOP \
      DESKTOP_SESSION \
      PATH \
      XDG_DATA_DIRS || true
    ${pkgs.systemd}/bin/systemctl --user start graphical-session.target || true
  '';
  terminalPackage = pkgs.alacritty;
  terminalCommand = lib.getExe terminalPackage;
  browserPackage = unstable.librewolf;
  browserCommand = lib.getExe browserPackage;
  passwordManagerPackage = pkgs._1password-gui;
  passwordManagerCommand = lib.getExe passwordManagerPackage;
  fileManagerPackage = pkgs.pcmanfm;
  fileManagerCommand = lib.getExe fileManagerPackage;
  networkEditorPackage = pkgs.networkmanagerapplet;
  networkEditorCommand = "${networkEditorPackage}/bin/nm-connection-editor";
  audioControlPackage = pkgs.pavucontrol;
  audioControlCommand = "${audioControlPackage}/bin/pavucontrol";
in
{
  home.sessionVariables = {
    XDG_CURRENT_DESKTOP = "i3";
    DESKTOP_SESSION = "i3";
  };

  xsession = {
    enable = true;

    windowManager.i3 = {
      enable = true;
      config = {
        modifier = mod;
        terminal = terminalCommand;
        menu = "vicinae toggle";

        fonts = {
          names = [ "monospace" ];
          size = 10.0;
        };

        gaps = {
          inner = 5;
          outer = 10;
        };

        floating = {
          modifier = mod;
          criteria = [
            { class = "Pavucontrol"; }
            { class = "Blueman-manager"; }
            { class = "Nm-connection-editor"; }
            { class = "Gnome-disks"; }
            { class = "Gparted"; }
            { title = "Open project"; }
          ];
        };

        window.commands = [
          {
            command = "border pixel 2";
            criteria = { class = "GCS"; };
          }
        ];

        startup = [
          {
            command = lib.getExe i3SessionEnvironmentScript;
            notification = false;
          }
          {
            command = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
            notification = false;
          }
          {
            command = "${pkgs.runtimeShell} -lc 'test -f \"$HOME/.background-image\" && ${pkgs.feh}/bin/feh --bg-fill \"$HOME/.background-image\" || true'";
            notification = false;
          }
        ];

        keybindings = {
          "${mod}+Return" = "exec ${terminalCommand}";
          "${mod}+space" = "exec vicinae toggle";
          "${mod}+b" = "exec ${browserCommand}";
          "${mod}+c" = "exec vicinae clipboard";
          "${mod}+p" = "exec ${passwordManagerCommand}";
          "${mod}+e" = "exec ${fileManagerCommand}";
          "${mod}+n" = "exec ${networkEditorCommand}";
          "${mod}+m" = "exec ${audioControlCommand}";

          "${mod}+q" = "kill";
          "${mod}+f" = "fullscreen toggle";
          "${mod}+v" = "floating toggle";
          "${mod}+Shift+r" = "reload";
          "${mod}+Shift+e" = "exec i3-msg exit";

          "${mod}+1" = "workspace number 1";
          "${mod}+2" = "workspace number 2";
          "${mod}+3" = "workspace number 3";
          "${mod}+4" = "workspace number 4";
          "${mod}+5" = "workspace number 5";
          "${mod}+6" = "workspace number 6";
          "${mod}+7" = "workspace number 7";
          "${mod}+8" = "workspace number 8";
          "${mod}+9" = "workspace number 9";
          "${mod}+0" = "workspace number 10";

          "${mod}+Shift+1" = "move container to workspace number 1";
          "${mod}+Shift+2" = "move container to workspace number 2";
          "${mod}+Shift+3" = "move container to workspace number 3";
          "${mod}+Shift+4" = "move container to workspace number 4";
          "${mod}+Shift+5" = "move container to workspace number 5";
          "${mod}+Shift+6" = "move container to workspace number 6";
          "${mod}+Shift+7" = "move container to workspace number 7";
          "${mod}+Shift+8" = "move container to workspace number 8";
          "${mod}+Shift+9" = "move container to workspace number 9";
          "${mod}+Shift+0" = "move container to workspace number 10";

          "${mod}+h" = "focus left";
          "${mod}+j" = "focus down";
          "${mod}+k" = "focus up";
          "${mod}+l" = "focus right";
          "${mod}+Shift+h" = "move left";
          "${mod}+Shift+j" = "move down";
          "${mod}+Shift+k" = "move up";
          "${mod}+Shift+l" = "move right";

          "${mod}+s" = "layout toggle split";
          "${mod}+period" = "gaps inner current set 10";
          "${mod}+comma" = "gaps inner current set 5";
          "${mod}+Shift+s" = "exec ${pkgs.maim}/bin/maim -s ${screenshotDir}/screenshot-$(date +%Y%m%d-%H%M%S).png";
          "${mod}+Shift+p" = "exec ${pkgs.maim}/bin/maim ${screenshotDir}/screenshot-$(date +%Y%m%d-%H%M%S).png";

          "XF86AudioMute" = "exec ${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
          "XF86AudioMicMute" = "exec ${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
          "XF86AudioPlay" = "exec ${pkgs.playerctl}/bin/playerctl play-pause";
          "XF86AudioPause" = "exec ${pkgs.playerctl}/bin/playerctl pause";
          "XF86AudioStop" = "exec ${pkgs.playerctl}/bin/playerctl stop";
          "XF86AudioNext" = "exec ${pkgs.playerctl}/bin/playerctl next";
          "XF86AudioPrev" = "exec ${pkgs.playerctl}/bin/playerctl previous";
          "XF86AudioForward" = "exec ${pkgs.playerctl}/bin/playerctl position 5+";
          "XF86AudioRewind" = "exec ${pkgs.playerctl}/bin/playerctl position 5-";
          "XF86AudioRaiseVolume" = "exec ${pkgs.wireplumber}/bin/wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+";
          "XF86AudioLowerVolume" = "exec ${pkgs.wireplumber}/bin/wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%-";
          "XF86MonBrightnessUp" = "exec ${pkgs.brightnessctl}/bin/brightnessctl -d acpi_video0 set 5%+";
          "XF86MonBrightnessDown" = "exec ${pkgs.brightnessctl}/bin/brightnessctl -d acpi_video0 set 5%-";
          "XF86KbdBrightnessUp" = "exec ${pkgs.brightnessctl}/bin/brightnessctl -d smc::kbd_backlight set 10%+";
          "XF86KbdBrightnessDown" = "exec ${pkgs.brightnessctl}/bin/brightnessctl -d smc::kbd_backlight set 10%-";
          "XF86Explorer" = "exec ${fileManagerCommand}";
          "XF86Launch1" = "exec vicinae toggle";
          "XF86Launch2" = "exec ${networkEditorCommand}";
        };

        modes.resize = {
          "h" = "resize shrink width 10 px or 10 ppt";
          "j" = "resize grow height 10 px or 10 ppt";
          "k" = "resize shrink height 10 px or 10 ppt";
          "l" = "resize grow width 10 px or 10 ppt";
          "Left" = "resize shrink width 10 px or 10 ppt";
          "Down" = "resize grow height 10 px or 10 ppt";
          "Up" = "resize shrink height 10 px or 10 ppt";
          "Right" = "resize grow width 10 px or 10 ppt";
          "Escape" = "mode default";
          "Return" = "mode default";
        };

        bars = [
          {
            position = "top";
            statusCommand = "${pkgs.i3status}/bin/i3status";
          }
        ];
      };

      extraConfig = ''
        bindsym ${mod}+r mode resize
      '';
    };
  };

  services.dunst.enable = true;

  home.packages = with pkgs; [
    terminalPackage
    browserPackage
    passwordManagerPackage
    fileManagerPackage
    brightnessctl
    dmenu
    dunst
    feh
    i3status
    maim
    networkEditorPackage
    audioControlPackage
    polkit_gnome
    slop
    xclip
    xorg.xev
    xorg.xprop
  ];

  home.activation.createI3WallpaperDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "${config.home.homeDirectory}/Pictures/Wallpapers/Favorites"
    mkdir -p "${config.home.homeDirectory}/Pictures/Wallpapers/Staging"
  '';
}
