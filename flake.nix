# flake.nix
{
  description = "@astn multi-system nix configuration";

  inputs = {
    # Core dependencies
    nixpkgs.url = "github:NixOS/nixpkgs/release-25.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    # Darwin support
    nix-darwin = {
      url = "github:LnL7/nix-darwin/nix-darwin-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Home Manager
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim = {
      url = "github:nix-community/nixvim";
    };
  };

  outputs =
    inputs @ { self
    , nixpkgs
    , nixpkgs-unstable
    , nix-darwin
    , home-manager
    , nixvim
    , ...
    }:
    let
      # Import our auto-discovery library
      autoDiscovery = import ./lib/auto-discovery.nix { inherit (nixpkgs) lib; };
      
      # System types to support
      supportedSystems = [ "x86_64-linux" "aarch64-darwin" "x86_64-darwin" ];

      # Common configuration for all systems
      sharedModules = [
        # Add your shared configuration here
        ({ config
         , pkgs
         , ...
         }: {
          nix.settings = {
            experimental-features = [ "nix-command" "flakes" ];
            substituters = [
              "https://cache.nixos.org"
            ];
            trusted-public-keys = [
              "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
            ];
          };
        })
        ({ config
         , pkgs
         , ...
         }:
          let
            unstable = import nixpkgs-unstable {
              system = pkgs.system;
              config.allowUnfree = true;
            };
          in
          {
            home-manager.extraSpecialArgs = { inherit unstable; };
          })
      ];

      # Discover valid machine directories using our abstraction
      validMachines = autoDiscovery.discoverDirectories {
        basePath = ./machines;
        excludeNames = [ "common" ];
        filterPredicate = dir: builtins.pathExists (dir + "/configuration.nix");
      };

      # Common system configuration based on OS type
      systemConfig = type:
        {
          nixos = {
            builder = nixpkgs.lib.nixosSystem;
            hmModule = home-manager.nixosModules.home-manager;
            systemModule = ./systems/nixos;
          };
          darwin = {
            builder = nix-darwin.lib.darwinSystem;
            hmModule = home-manager.darwinModules.home-manager;
            systemModule = ./systems/darwin;
          };
        }.${type};

      # Function to create machine configuration
      buildMachine = name:
        let
          # Use the new function to determine system type
          systemType = autoDiscovery.extractSystemType {
            inherit name;
            machinesPath = ./machines;
          };

          # Detect OS type from system string
          osType =
            if builtins.match ".*-linux" systemType != null
            then "nixos"
            else "darwin";

          # Get appropriate system configuration
          sysConfig = systemConfig osType;

          # Hardware configuration path - with fallback
          hardwareConfig =
            let
              path = ./machines + "/${name}/hardware-configuration.nix";
              pathExists = builtins.pathExists path;
            in
            if pathExists
            then path
            else null;

          # User configuration using auto-discovery
          usersDir = ./users;
          
          unstable = import nixpkgs-unstable {
            system = systemType;
            config.allowUnfree = true;
          };

          # Discover valid user directories
          validUsers = autoDiscovery.discoverDirectories {
            basePath = usersDir;
            filterPredicate = dir: builtins.pathExists (dir + "/default.nix");
          };
          
          # Function to build user imports
          buildUserConfig = user: {
            name = user;
            value = { config, pkgs, lib, ... }:
              import (usersDir + "/${user}") { inherit config pkgs lib unstable; };
          };

          # Create attrset of user configs
          userConfigSet = builtins.listToAttrs (map buildUserConfig validUsers);

          # Machine modules - with hardware if it exists
          machineModules =
            [
              (./machines + "/${name}/configuration.nix")
            ]
            ++ (
              if hardwareConfig != null
              then [ hardwareConfig ]
              else [ ]
            );
        in
        {
          inherit name;
          value = sysConfig.builder {
            system = systemType;
            specialArgs = { inherit inputs unstable; };
            modules =
              machineModules
              ++ [
                ./systems/common
                sysConfig.systemModule
                sysConfig.hmModule
                { nixpkgs.overlays = [ (import overlays/gcs.nix) ]; }
                {
                  home-manager.useGlobalPkgs = true;
                  home-manager.useUserPackages = true;
                  home-manager.users = userConfigSet;
                  home-manager.backupFileExtension = "hmbak";
                  home-manager.extraSpecialArgs = { inherit unstable; };
                  home-manager.sharedModules = [ nixvim.homeManagerModules.default ];
                }
              ]
              ++ sharedModules;
          };
        };

      # Build all machines
      machines = map buildMachine validMachines;

      # Convert to attribute set and split by OS type
      machineAttrs = builtins.listToAttrs machines;

      # Function to filter by system type pattern
      filterSystems = pattern:
        nixpkgs.lib.filterAttrs
          (name: _: 
            let 
              systemType = autoDiscovery.extractSystemType { inherit name; machinesPath = ./machines; };
            in
            builtins.match pattern systemType != null
          )
          machineAttrs;

      # Split by OS type
      nixosConfigs = filterSystems ".*-linux";
      darwinConfigs = filterSystems ".*-darwin";
    in
    {
      # Expose our library for other flakes to use
      lib = {
        autoDiscovery = import ./lib/auto-discovery.nix { inherit (nixpkgs) lib; };
      };
      
      # System configurations
      nixosConfigurations = nixosConfigs;
      darwinConfigurations = darwinConfigs;
    };
}
# vim: set tabstop=2 softtabstop=2 shiftwidth=2 expandtab

