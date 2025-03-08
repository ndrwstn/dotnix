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
      ({ config, pkgs, ... }: let
        unstable = import nixpkgs-unstable {
          system = pkgs.system;
          config.allowUnfree = true;
        };
      in {
        home-manager.extraSpecialArgs = { inherit unstable; };
      })
    ];

    # Get all directory names in machines/
    machineNames = builtins.attrNames (builtins.readDir ./machines);
    
    # Filter to only directories that have configuration.nix
    validMachines = builtins.filter (name: 
      name != "common" && 
      builtins.pathExists (./machines + "/${name}/configuration.nix")
    ) machineNames;

    # Common system configuration based on OS type
    systemConfig = type: {
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
    buildMachine = name: let
      # Detect system type from file or default
      systemFile = ./machines + "/${name}/system.nix";
      systemType = if builtins.pathExists systemFile 
                  then import systemFile
                  else "x86_64-linux"; # Default to x86_64-linux
      
      # Detect OS type from system string
      osType = if builtins.match ".*-linux" systemType != null
               then "nixos"
               else "darwin";
      
      # Get appropriate system configuration
      sysConfig = systemConfig osType;
      
      # Hardware configuration path - with fallback
      hardwareConfig = let
        path = ./machines + "/${name}/hardware-configuration.nix";
      in if builtins.pathExists path then path else null;
      
      # User configuration - reads directory for users
      usersDir = ./users;
      usersList = builtins.attrNames (builtins.readDir usersDir);
      
      # Function to build user imports
      buildUserConfig = user: let
        userPath = usersDir + "/${user}";
        hasConfig = builtins.pathExists (userPath + "/default.nix");
      in if hasConfig then {
        name = user;
        config = { ... }: {
          imports = [ 
            userPath
            # Add nvf for austin only, as an example of conditional imports
            (if user == "austin" then nvf.homeManagerModules.default else {})
          ];
        };
      } else null;
      
      # Generate user configurations, filter out nulls
      userConfigs = builtins.filter (x: x != null) (map buildUserConfig usersList);
      
      # Create attrset of user configs
      userConfigSet = builtins.listToAttrs (map (cfg: {
        name = cfg.name;
        value = cfg.config;
      }) userConfigs);
      
      # Machine modules - with hardware if it exists
      machineModules = [
        (./machines + "/${name}/configuration.nix")
      ] ++ (if hardwareConfig != null then [ hardwareConfig ] else []);
    in {
      inherit name;
      value = sysConfig.builder {
        system = systemType;
        specialArgs = { inherit inputs; };
        modules = machineModules ++ [
          ./systems/common
          sysConfig.systemModule
          sysConfig.hmModule
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users = userConfigSet;
            home-manager.backupFileExtension = "hmbak";
          }
        ] ++ sharedModules;
      };
    };
    
    # Build all machines
    machines = map buildMachine validMachines;
    
    # Convert to attribute set and split by OS type
    machineAttrs = builtins.listToAttrs machines;
    
    # Function to filter by system type pattern
    filterSystems = pattern: builtins.filterAttrs 
      (name: _: builtins.match pattern (builtins.readFile 
        (./machines + "/${name}/system.nix")) != null) 
      machineAttrs;
    
    # Split by OS type
    nixosConfigs = filterSystems ".*-linux";
    darwinConfigs = filterSystems ".*-darwin";
  in {
    nixosConfigurations = nixosConfigs;
    darwinConfigurations = darwinConfigs;
  };
}

# vim: set tabstop=2 softtabstop=2 shiftwidth=2 expandtab