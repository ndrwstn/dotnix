# systems/nixos/1password.nix
# 1Password configuration for NixOS systems
{ pkgs, ... }:

{
  # Enable 1Password CLI and GUI programs
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
      ExecStart = "${pkgs._1password-gui}/bin/1password --silent";
      Restart = "on-failure";
      Type = "simple";
    };
  };
}
