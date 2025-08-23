# systems/common/default.nix

{ config
, pkgs
, lib
, ...
}: {
  imports = [
    ./users.nix
  ];

  options = {
    # Define custom options for machine metadata
    _astn = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = { };
      description = "Custom namespace for machine-specific metadata";
    };
  };

  config = {
    # Common system packages
    environment.systemPackages = with pkgs; [
      # Core utilities
      jdk17
      nh
      vim
      wget
      zsh

      # Sops-related packages
      sops
      age
    ];

    # Allow unfree packages globally
    nixpkgs.config.allowUnfree = true;
  };
}
