# systems/nixos/1password.nix
# 1Password configuration for NixOS systems
{ ... }:

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
        ungoogled-chromium
        firefox
      '';
      mode = "0644";
    };
  };

}
