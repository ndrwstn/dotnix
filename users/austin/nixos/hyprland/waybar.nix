# users/austin/nixos/hyprland/waybar.nix
# Waybar configuration for Hyprland
{ pkgs, ... }:

let
  cliphistMenu = pkgs.writeShellScript "waybar-cliphist-menu" ''
    set -eu

    selection="$(${pkgs.cliphist}/bin/cliphist list | ${pkgs.wofi}/bin/wofi --dmenu --prompt 'Clipboard')"

    if [ -n "''${selection}" ]; then
      printf '%s' "''${selection}" | ${pkgs.cliphist}/bin/cliphist decode | ${pkgs.wl-clipboard}/bin/wl-copy
    fi
  '';

in
{
  programs.waybar = {
    enable = true;
    systemd.enable = true;

    settings = [
      {
        layer = "top";
        position = "top";
        height = 34;
        spacing = 6;

        modules-left = [ "hyprland/workspaces" ];
        modules-center = [ "hyprland/window" ];
        modules-right = [
          "tray"
          "network"
          "battery"
          "clock"
          "custom/power"
        ];

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

        network = {
          format-wifi = "📶 {signalStrength}%";
          format-ethernet = "🌐 {ifname}";
          format-disconnected = "⚠️";
          tooltip-format = "{ifname} via {gwaddr}";
          on-click = "${pkgs.networkmanagerapplet}/bin/nm-connection-editor";
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
          tooltip-format = "{timeTo}, {power:0.1f}W";
          on-click = "${pkgs.wlogout}/bin/wlogout";
        };

        "custom/power" = {
          format = "⏻";
          tooltip = false;
          on-click = "${pkgs.wlogout}/bin/wlogout";
        };

        tray = {
          icon-size = 16;
          spacing = 4;
        };
      }
    ];

    style = ''
      @import "colors.css";

      * {
        font-family: "DejaVu Sans", sans-serif;
        font-size: 14px;
      }

      window#waybar {
        background-color: alpha(@surface, 0.94);
        border-bottom: 2px solid alpha(@accent, 0.80);
        color: @fg;
        transition-property: background-color;
        transition-duration: .5s;
      }

      window#waybar.hidden {
        opacity: 0.2;
      }

      #workspaces button {
        padding: 0 10px;
        background-color: alpha(@surface-alt, 0.45);
        color: @fg;
        border: 1px solid transparent;
        border-radius: 10px;
        margin: 5px 4px;
      }

      #workspaces button:hover {
        background: alpha(@accent-soft, 0.75);
        border-color: alpha(@accent, 0.40);
      }

      #workspaces button.focused {
        background-color: @accent;
        color: @on-accent;
        border-color: alpha(@accent-alt, 0.85);
        box-shadow: inset 0 -2px @accent-alt;
      }

      #workspaces button.urgent {
        background-color: @urgent;
        color: @bg;
      }

      #mode {
        background-color: @accent-alt;
        color: @bg;
        border-radius: 10px;
      }

      #clock,
      #battery,
      #network,
      #custom-power,
      #tray,
      #mode,
      #idle_inhibitor,
      #scratchpad {
        padding: 0 10px;
        color: @fg;
      }

      #custom-power {
        padding-right: 14px;
        font-size: 16px;
      }

      #clock {
        background: alpha(@accent, 0.92);
        color: @on-accent;
        border-radius: 12px;
        margin: 4px 2px;
      }

      #network,
      #battery,
      #custom-power,
      #tray {
        background: alpha(@surface-alt, 0.90);
        border: 1px solid alpha(@border, 0.75);
        border-radius: 12px;
        margin: 4px 2px;
      }

      #custom-power {
        background: alpha(@accent-alt, 0.88);
        color: @bg;
      }

      #window {
        background: alpha(@surface-alt, 0.72);
        border: 1px solid alpha(@border, 0.55);
        border-radius: 12px;
        padding: 0 14px;
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
          background-color: @fg;
          color: @bg;
        }
      }

      #battery.critical:not(.charging) {
        background-color: @urgent;
        color: @bg;
        animation-name: blink;
        animation-duration: 0.5s;
        animation-timing-function: linear;
        animation-iteration-count: infinite;
        animation-direction: alternate;
      }

      label:focus {
        background-color: @bg;
      }

      #pulseaudio.muted {
        color: @accent;
      }

      #wireplumber.muted {
        color: @accent;
      }

      #temperature.critical {
        background-color: @urgent;
        color: @bg;
      }

      #battery.warning,
      #network.disconnected {
        background-color: @warning;
        color: @bg;
      }
    '';
  };
}
