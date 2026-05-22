# systems/common/default.nix

{ config
, pkgs
, lib
, ...
}: {
  imports = [
    ./users.nix
    ./secrets.nix
    ./clamav.nix
    ./llm.nix
  ];

  options = {
    # Define custom options for machine metadata while preserving room for
    # ad-hoc metadata consumed by flake auto-discovery and other modules.
    _astn = lib.mkOption {
      type = lib.types.submodule {
        freeformType = lib.types.attrsOf lib.types.anything;
        options.machine.windowManagers = lib.mkOption {
          type = lib.types.listOf (lib.types.enum [
            "gnome"
            "hyprland"
            "i3"
          ]);
          default = [
            "gnome"
            "hyprland"
          ];
          description = ''
            Graphical desktop environments/window managers to enable on NixOS.
            Hosts can set this to a subset or to an empty list for headless use.
          '';
        };
      };
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
