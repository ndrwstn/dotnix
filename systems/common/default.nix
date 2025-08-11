# systems/common/default.nix

{ config
, pkgs
, lib
, ...
}: {
  imports = [ 
    ./users.nix
    # ./sops.nix  # Uncomment after sops is fully set up
  ];

  options = {
    # Define custom options for machine metadata
    _astn = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = {};
      description = "Custom namespace for machine-specific metadata";
    };
  };

  config = {
    # Common system packages
    environment.systemPackages = with pkgs; [
      jdk17
      nh
      vim
      wget
      zsh
    ];

    # Allow unfree packages globally
    nixpkgs.config.allowUnfree = true;
  };
}
