# users/austin/nixos/hyprland/wlogout.nix
# Wlogout power menu configuration
{ pkgs, config, ... }:

{
  programs.wlogout = {
    enable = true;

    layout = [
      {
        label = "lock";
        action = "loginctl lock-session";
        text = "Lock";
        keybind = "l";
      }
      {
        label = "logout";
        action = "hyprctl dispatch exit";
        text = "Logout";
        keybind = "x";
      }
      {
        label = "sleep";
        action = "${pkgs.bash}/bin/bash -c 'echo s2idle > /sys/power/mem_sleep && systemctl suspend'";
        text = "Sleep";
        keybind = "e";
      }
      {
        label = "reboot";
        action = "systemctl reboot";
        text = "Reboot";
        keybind = "r";
      }
      {
        label = "shutdown";
        action = "systemctl poweroff";
        text = "Shutdown";
        keybind = "s";
      }
      {
        label = "suspend";
        action = "systemctl suspend";
        text = "Suspend";
        keybind = "u";
      }
    ];

    style = ''
      @import url("${builtins.toString config.xdg.configHome}/wlogout/colors.css");

      * {
        background-image: none;
        font-size: 10pt;
        font-family: "Cantarell", sans-serif;
      }

      window {
        background-color: alpha(@bg, 0.94);
      }

      button {
        color: @fg;
        background-color: alpha(@surface, 0.90);
        border-style: solid;
        border-width: 2px;
        border-radius: 16px;
        border-color: alpha(@border, 0.85);
        background-repeat: no-repeat;
        background-position: center;
        background-size: 25%;
        margin: 10px;
        min-width: 120px;
        min-height: 120px;
        padding: 12px;
      }

      button:focus, button:active, button:hover {
        color: @on-accent;
        background-color: alpha(@accent, 0.95);
        border-color: alpha(@accent-alt, 0.95);
        outline-style: none;
      }

      #shutdown,
      #reboot {
        border-color: alpha(@urgent, 0.9);
      }

      #shutdown:hover,
      #shutdown:focus,
      #shutdown:active,
      #reboot:hover,
      #reboot:focus,
      #reboot:active {
        background-color: alpha(@urgent, 0.95);
        border-color: alpha(@urgent, 1.0);
        color: @bg;
      }

      #lock {
        background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/lock.png"));
      }

      #logout {
        background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/logout.png"));
      }

      #sleep {
        background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/suspend.png"));
      }

      #suspend {
        background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/suspend.png"));
      }

      #reboot {
        background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/reboot.png"));
      }

      #shutdown {
        background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/shutdown.png"));
      }
    '';
  };
}
