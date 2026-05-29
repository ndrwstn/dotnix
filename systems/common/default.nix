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

        options.presets = {
          gui.enable = lib.mkOption {
            type = lib.types.bool;
            default = config._astn.machine.windowManagers != [ ];
            defaultText = lib.literalExpression ''config._astn.machine.windowManagers != [ ]'';
            description = ''
              Enable baseline GUI applications for graphical NixOS machines.
            '';
          };

          graphics.enable = lib.mkEnableOption "graphics application preset";
          maker.enable = lib.mkEnableOption "CAD/maker application preset";
          recording.enable = lib.mkEnableOption "recording application preset";
          office.enable = lib.mkEnableOption "office application preset";
          radio.enable = lib.mkEnableOption "radio/SDR application and hardware preset";
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
      nmap
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
