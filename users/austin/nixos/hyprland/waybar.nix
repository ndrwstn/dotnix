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

  bluetoothStatus = pkgs.writeShellScript "waybar-bluetooth-status" ''
    set -eu

    if ! ${pkgs.bluez}/bin/bluetoothctl show >/dev/null 2>&1; then
      printf '{"text":"󰂲 off","tooltip":"Bluetooth unavailable"}\n'
      exit 0
    fi

    if ${pkgs.bluez}/bin/bluetoothctl show | ${pkgs.gnugrep}/bin/grep -q 'Powered: yes'; then
      connected="$(${pkgs.bluez}/bin/bluetoothctl devices Connected | ${pkgs.coreutils}/bin/wc -l)"
      if [ "''${connected}" -gt 0 ]; then
        printf '{"text":"󰂱 %s","tooltip":"Bluetooth on (%s connected)"}\n' "''${connected}" "''${connected}"
      else
        printf '{"text":"󰂯 on","tooltip":"Bluetooth on"}\n'
      fi
    else
      printf '{"text":"󰂲 off","tooltip":"Bluetooth off"}\n'
    fi
  '';
in
{
  programs.waybar = {
    enable = true;

    settings = [
      {
        layer = "top";
        position = "top";
        height = 34;
        spacing = 6;

        modules-left = [ "hyprland/workspaces" "hyprland/window" ];
        modules-center = [ "clock" ];
        modules-right = [
          "custom/clipboard"
          "backlight"
          "pulseaudio"
          "cpu"
          "memory"
          "temperature"
          "network"
          "custom/bluetooth"
          "battery"
          "custom/power"
          "tray"
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

        "custom/clipboard" = {
          format = "";
          tooltip = false;
          on-click = "${cliphistMenu}";
        };

        backlight = {
          device = "acpi_video0";
          format = "{percent}% ";
          tooltip-format = "Brightness: {percent}%";
          scroll-step = 5;
          on-scroll-up = "${pkgs.brightnessctl}/bin/brightnessctl -d acpi_video0 set 5%+";
          on-scroll-down = "${pkgs.brightnessctl}/bin/brightnessctl -d acpi_video0 set 5%-";
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
          scroll-step = 5;
          on-click = "${pkgs.pavucontrol}/bin/pavucontrol";
          on-click-right = "${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
        };

        cpu = {
          format = "{usage}% ";
          tooltip = false;
        };

        memory = {
          format = "{}% ";
          tooltip-format = "Memory usage: {used:0.1f}G / {total:0.1f}G";
        };

        temperature = {
          critical-threshold = 85;
          format = "{temperatureC}°C ";
          tooltip = false;
        };

        network = {
          format-wifi = "📶 {signalStrength}%";
          format-ethernet = "🌐 {ifname}";
          format-disconnected = "⚠️";
          tooltip-format = "{ifname} via {gwaddr}";
          on-click = "${pkgs.networkmanagerapplet}/bin/nm-connection-editor";
        };

        "custom/bluetooth" = {
          exec = "${bluetoothStatus}";
          return-type = "json";
          interval = 10;
          on-click = "${pkgs.blueman}/bin/blueman-manager";
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
      * {
        font-family: "DejaVu Sans", sans-serif;
        font-size: 14px;
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
      #custom-bluetooth,
      #custom-clipboard,
      #custom-power,
      #wireplumber,
      #custom-media,
      #tray,
      #mode,
      #idle_inhibitor,
      #scratchpad {
        padding: 0 10px;
        color: #D8DEE9;
      }

      #custom-power {
        padding-right: 14px;
        font-size: 16px;
      }

      #custom-clipboard,
      #custom-bluetooth,
      #backlight,
      #network,
      #pulseaudio,
      #battery,
      #custom-power {
        background: rgba(59, 66, 82, 0.55);
        border-radius: 8px;
        margin: 4px 2px;
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
