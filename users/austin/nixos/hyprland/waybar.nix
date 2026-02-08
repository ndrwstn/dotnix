# users/austin/nixos/hyprland/waybar.nix
# Waybar configuration for Hyprland
{ pkgs, ... }:

{
  programs.waybar = {
    enable = true;

    settings = [
      {
        layer = "top";
        position = "top";
        height = 30;
        spacing = 4;

        modules-left = [ "hyprland/workspaces" "hyprland/window" ];
        modules-center = [ "clock" ];
        modules-right = [ "pulseaudio" "network" "battery" "tray" ];

        "hyprland/workspaces" = {
          format = "{name}";
          format-icons = {
            "1" = "1";
            "2" = "2";
            "3" = "3";
            "4" = "4";
            "5" = "5";
            "6" = "6";
            "7" = "7";
            "8" = "8";
            "9" = "9";
            "10" = "10";
          };
          persistent-workspaces = {
            "*" = [ 1 2 3 4 5 6 7 8 9 10 ];
          };
        };

        "hyprland/window" = {
          format = "{}";
          max-length = 50;
        };

        clock = {
          format = "{:%Y-%m-%d %H:%M}";
          tooltip-format = "{:%Y-%m-%d %H:%M:%S}";
        };

        pulseaudio = {
          format = "{volume}% {icon}";
          format-bluetooth = "{volume}% {icon}";
          format-muted = "🔇";
          format-icons = {
            "headphones" = "🎧";
            "handsfree" = "🎧";
            "headset" = "🎧";
            "phone" = "📱";
            "portable" = "🔊";
            "car" = "🚗";
            "default" = [ "🔈" "🔉" "🔊" ];
          };
        };

        network = {
          format-wifi = "📶 {signalStrength}%";
          format-ethernet = "🌐 {ifname}";
          format-disconnected = "⚠️";
          tooltip-format = "{ifname}";
        };

        battery = {
          states = {
            "warning" = 30;
            "critical" = 15;
          };
          format = "{capacity}% {icon}";
          format-charging = "⚡ {capacity}%";
          format-plugged = "🔌 {capacity}%";
          format-icons = [ "🪫" "🪫" "🔋" "🔋" "🔋" "🔋" "🔋" "🔋" "🔋" "🔋" ];
        };

        tray = {
          icon-size = 16;
          spacing = 4;
        };
      }
    ];

    style = ''
      * {
        font-family: "DejaVu Sans", sans-serif;
        font-size: 13px;
      }

      window#waybar {
        background-color: rgba(46, 52, 64, 0.9);
        border-bottom: 2px solid rgba(94, 129, 172, 0.5);
        color: #D8DEE9;
        transition-property: background-color;
        transition-duration: .5s;
      }

      window#waybar.hidden {
        opacity: 0.2;
      }

      #workspaces button {
        padding: 0 5px;
        background-color: transparent;
        color: #D8DEE9;
        border-bottom: 2px solid transparent;
      }

      #workspaces button:hover {
        background: rgba(94, 129, 172, 0.2);
      }

      #workspaces button.focused {
        background-color: #5E81AC;
        border-bottom: 2px solid #88C0D0;
      }

      #workspaces button.urgent {
        background-color: #BF616A;
      }

      #mode {
        background-color: #64727D;
        border-bottom: 2px solid #ffffff;
      }

      #clock,
      #battery,
      #cpu,
      #memory,
      #disk,
      #temperature,
      #backlight,
      #network,
      #pulseaudio,
      #wireplumber,
      #custom-media,
      #tray,
      #mode,
      #idle_inhibitor,
      #scratchpad {
        padding: 0 10px;
        color: #D8DEE9;
      }

      #window,
      #workspaces {
        margin: 0 4px;
      }

      /* If workspaces is the leftmost module, omit left margin */
      .modules-left widget:first-child > #workspaces {
        margin-left: 0;
      }

      /* If workspaces is the rightmost module, omit right margin */
      .modules-right widget:last-child > #workspaces {
        margin-right: 0;
      }

      @keyframes blink {
        to {
          background-color: #ffffff;
          color: #000000;
        }
      }

      #battery.critical:not(.charging) {
        background-color: #BF616A;
        color: #D8DEE9;
        animation-name: blink;
        animation-duration: 0.5s;
        animation-timing-function: linear;
        animation-iteration-count: infinite;
        animation-direction: alternate;
      }

      label:focus {
        background-color: #000000;
      }

      #pulseaudio.muted {
        color: #BF616A;
      }

      #wireplumber.muted {
        color: #BF616A;
      }

      #temperature.critical {
        background-color: #BF616A;
      }
    '';
  };
}
