# systems/nixos/1password.nix
# 1Password configuration for NixOS systems
{ ... }:

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
}
