# systems/nixos/1password.nix
# 1Password configuration for NixOS systems
{ pkgs, lib, ... }:

let
  onePasswordGui = lib.getExe pkgs._1password-gui;
in
{
  # Enable 1Password CLI and GUI programs
  # Keep package ownership here so NixOS provides the wrapped `op`
  # binary and desktop-app integration.
  programs._1password = {
    enable = true;
  };

  programs._1password-gui = {
    enable = true;
    # Set polkit permissions for user "austin"
    polkitPolicyOwners = [ "austin" ];
  };

  # Configure browser integration
  environment.etc = {
    "1password/custom_allowed_browsers" = {
      text = ''
        chromium
        ungoogled-chromium
        firefox
      '';
      mode = "0644";
    };
  };

  # Systemd user service to run 1Password silently in background
  systemd.user.services._1password = {
    description = "1Password";
    partOf = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${onePasswordGui} --silent";
      Restart = "on-failure";
      Type = "simple";
      # Force XWayland to fix auth dialog rendering on Hyprland/Wayland
      # https://1password.community/discussions/1password/authetication-prompt-not-showing-up-on-wayland-hyprland/109939
      Environment = [ "ELECTRON_OZONE_PLATFORM_HINT=x11" ];
    };
  };
}
