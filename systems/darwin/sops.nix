# systems/darwin/sops.nix
{ config, lib, pkgs, ... }:

{
  # Darwin-specific sops configuration
  options.sops = lib.mkOption {
    type = lib.types.attrsOf lib.types.anything;
    default = { };
    description = "Placeholder for sops options on Darwin";
  };

  config = {
    # Set up the age key directory and create a custom activation script
    system.activationScripts.postActivation.text = lib.mkAfter ''
      # Create sops-nix directories
      echo "Setting up sops-nix directories..."
      mkdir -p /var/lib/sops-nix
      chmod 700 /var/lib/sops-nix
      
      # Create a symlink to the user's age key if it exists
      if [ -f "$HOME/.config/sops/age/keys.txt" ]; then
        echo "Linking user age key to system location..."
        ln -sf "$HOME/.config/sops/age/keys.txt" /var/lib/sops-nix/key.txt
      fi
    '';
  };
}
