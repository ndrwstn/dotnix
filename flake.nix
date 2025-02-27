{
  description = "@astn multi-system nix configuration";

  inputs = {
    # Core dependencies
    nixpkgs.url = "github:NixOS/nixpkgs/";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    
    # Darwin support
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    # Home Manager
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Neovim (??/nvf )
    nvf = {
      url = "github:notashelf/nvf";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs = inputs@{ 
    self,
    nixpkgs,
    nixpkgs-unstable,
    nix-darwin,
    home-manager,
    nvf,
    ...
  }: let
    
    # System types to support
    supportedSystems = [ "x86_64-linux" "aarch64-darwin" "x86_64-darwin" ];
    
    # Common configuration for all systems
    sharedModules = [
      # Add your shared configuration here
      ({ config, pkgs, ... }: {
        nix.settings.experimental-features = [ "nix-command" "flakes" ];
      })
      ({ config, pkgs, ... }: let
        unstable = import nixpkgs-unstable {
          system = pkgs.system;
          config.allowUnfree = true;
        };
      in {
        home-manager.extraSpecialArgs = { inherit unstable; };
      })
    ];

  in {
    # NixOS configurations
    nixosConfigurations = {
      # NixOS / Macbook Pro 13"
      Silver = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./machines/silver/configuration.nix
          ./machines/silver/hardware-configuration.nix
          ./machines/common
          ./systems/nixos
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.austin = { ... }: {
              imports = [
                ./users/austin
                nvf.homeManagerModules.default
              ];
            };
            home-manager.users.jessica = import ./users/jessica;
            home-manager.backupFileExtension = "hmbak";
          }
        ] ++ sharedModules;
      };
      
      # Future systems - commented out until needed
      /*
      Molybdenum = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./machines/molybdenum/configuration.nix
          ./machines/molybdenum/hardware-configuration.nix
          ./machines/common
          ./systems/nixos
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.austin = import ./users/austin.nix;
          }
        ] ++ sharedModules;
      };
      
      Siberia = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./machines/siberia/configuration.nix
          ./machines/siberia/hardware-configuration.nix
          ./machines/common
          ./systems/nixos
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.austin = import ./users/austin.nix;
          }
        ] ++ sharedModules;
      };
      */
    };

    # Darwin configurations
    darwinConfigurations = {
      /* Future systems - commented out until needed
      Monaco = nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        modules = [
          ./machines/monaco/configuration.nix
          ./machines/common
          ./systems/darwin
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.austin = import ./users/austin.nix;
          }
        ] ++ sharedModules;
      };

      Plutonium = nix-darwin.lib.darwinSystem {
        system = "x86_64-darwin";
        modules = [
          ./machines/plutonium/configuration.nix
          ./machines/common
          ./systems/darwin
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.austin = import ./users/austin.nix;
          }
        ] ++ sharedModules;
      };
      */
    };
  };
}

# vim: set tabstop=2 softtabstop=2 shiftwidth=2 expandtab 
