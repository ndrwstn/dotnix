# users/austin/nixos/hyprland/wlogout.nix
# Wlogout power menu configuration
{ pkgs, ... }:

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
        keybind = "e";
      }
      {
        label = "suspend";
        action = "systemctl suspend";
        text = "Suspend";
        keybind = "u";
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
    ];

    style = ''
      * {
        background-image: none;
        font-size: 10pt;
        font-family: "Cantarell", sans-serif;
      }

      window {
        background-color: rgba(30, 30, 46, 0.95);
      }

      button {
        color: #FFFFFF;
        background-color: rgba(255, 255, 255, 0.1);
        border-style: solid;
        border-width: 2px;
        border-radius: 8px;
        border-color: rgba(255, 255, 255, 0.3);
        background-repeat: no-repeat;
        background-position: center;
        background-size: 25%;
        margin: 5px;
        min-width: 80px;
        min-height: 80px;
        padding: 5px;
      }

      button:focus, button:active, button:hover {
        background-color: rgba(94, 129, 172, 0.5);
        border-color: rgba(94, 129, 172, 1);
        outline-style: none;
      }

      #lock {
        background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/lock.png"));
      }

      #logout {
        background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/logout.png"));
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
