# flake.nix
{
  description = "@astn multi-system nix configuration";

  inputs = {
    # Core dependencies
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    # Darwin support
    nix-darwin = {
      url = "github:LnL7/nix-darwin/nix-darwin-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Darwin login items management
    darwin-login-items.url = "github:uncenter/nix-darwin-login-items";

    # Home Manager
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Neovim configuration
    nixvim.url = "github:nix-community/nixvim/nixos-26.05";


    # Secrets management
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Impermanence for explicitly provisioned disposable VMs.
    impermanence = {
      url = "github:nix-community/impermanence";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nixautopkgs flake
    nixautopkgs.url = "github:ndrwstn/nixautopkgs/master";

    # NUR repository for Firefox extensions
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # MCP servers for AI tooling
    mcp-servers-nix = {
      url = "github:natsukium/mcp-servers-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Vicinae launcher (Raycast-like for Linux)
    # Note: Not using 'follows' to ensure we use upstream's nixpkgs pin,
    # which aligns with their Cachix cache and avoids unnecessary rebuilds
    vicinae.url = "github:vicinaehq/vicinae";
  };

  outputs =
    inputs @ { self
    , nixpkgs
    , nixpkgs-unstable
    , nix-darwin
    , darwin-login-items
    , home-manager
    , nixvim
    , agenix
    , impermanence
    , nixautopkgs
    , mcp-servers-nix
    , nur
    , vicinae

    , ...
    }:
    let
      # Import our auto-discovery library
      autoDiscovery = import ./lib/auto-discovery.nix { inherit (nixpkgs) lib; };

      # System types to support
      supportedSystems = [ "x86_64-linux" "aarch64-darwin" "x86_64-darwin" ];

      # Common configuration for all systems
      sharedModules = [
        ({ config
         , pkgs
         , lib
         , ...
         }:
          let
            nixosOverlays = import ./overlays;
            unstable = import nixpkgs-unstable {
              system = pkgs.stdenv.hostPlatform.system;
              config.allowUnfree = true;
              overlays = lib.optionals pkgs.stdenv.isLinux nixosOverlays;
            };
            autopkgs = nixautopkgs.packages.${pkgs.stdenv.hostPlatform.system};
            mcppkgs = mcp-servers-nix.packages.${pkgs.stdenv.hostPlatform.system};
          in
          {
            home-manager.extraSpecialArgs = { inherit unstable autopkgs mcppkgs nur; };
          })
      ];

      # Discover valid machine directories using our abstraction
      validMachines = autoDiscovery.discoverDirectories {
        basePath = ./machines;
        excludeNames = [ "common" ];
        filterPredicate = dir: builtins.pathExists (dir + "/configuration.nix");
      };

      # Machine composition is declared next to each machine, rather than
      # inferred from configuration comments or system-name regexes.
      machineMetadata = name: import (./machines + "/${name}/metadata.nix");

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
          metadata = machineMetadata name;
          systemType = metadata.system;

          # Detect OS type from system string
          osType = if nixpkgs.lib.hasSuffix "-linux" systemType then "nixos" else "darwin";

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

          # User configuration is selected from machine metadata.  A user may
          # provide a role-specific profile (for example, Austin's minimal
          # virtual profile); otherwise their default profile is used.
          usersDir = ./users;

          unstable = import nixpkgs-unstable {
            system = systemType;
            config.allowUnfree = true;
            overlays = nixpkgs.lib.optionals (osType == "nixos") (import ./overlays);
          };

          autopkgs = nixautopkgs.packages.${systemType};
          mcppkgs = mcp-servers-nix.packages.${systemType};

          # Function to build user imports
          buildUserConfig = user: {
            name = user;
            value = { config, pkgs, lib, osConfig, hostName, ... }:
              let
                roleProfile = usersDir + "/${user}/${metadata.role}.nix";
                userProfile =
                  if builtins.pathExists roleProfile
                  then roleProfile
                  else usersDir + "/${user}";
              in
              import userProfile { inherit config pkgs lib osConfig unstable autopkgs mcppkgs hostName; };
          };

          # Create attrset of user configs
          userConfigSet = builtins.listToAttrs (map buildUserConfig metadata.users);

          # System account declarations are selected by machine metadata too.
          userSystemModules = map
            (user: usersDir + "/${user}/system.nix")
            metadata.users;

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

          roleDir = ./roles + "/${metadata.role}";
          roleModule = roleDir + "/default.nix";
          platformRoleModule = roleDir + "/${osType}.nix";
          roleModules =
            [ roleModule ]
            ++ nixpkgs.lib.optional (builtins.pathExists platformRoleModule) platformRoleModule;
          featureModules = builtins.filter (module: module != null) (map
            (feature:
              let
                featurePath = ./features + "/${feature}";
                filePath = ./features + "/${feature}.nix";
                directoryPath = featurePath + "/default.nix";
              in
              if builtins.pathExists filePath then filePath
              else if builtins.pathExists directoryPath then directoryPath
              else throw "Unknown feature '${feature}': expected ${toString filePath} or ${toString directoryPath}")
            metadata.features);
        in
        {
          inherit name;
          value = sysConfig.builder {
            system = systemType;
            specialArgs = { inherit inputs unstable autopkgs; };
            modules =
              let lib = nixpkgs.lib; in
              machineModules
              ++ userSystemModules
              ++ [
                ./common
                ({ ... }: { _astn.machine = metadata; })
              ]
              ++ roleModules
              ++ featureModules
              ++ [
                sysConfig.systemModule
                sysConfig.hmModule
              ]
              # Add darwin-login-items module for Darwin systems only
              ++ lib.optionals (osType == "darwin") [
                darwin-login-items.darwinModules.default
              ]
              ++ [
                ({ config, ... }: {
                  home-manager.useGlobalPkgs = true;
                  home-manager.useUserPackages = true;
                  home-manager.users = userConfigSet;
                  home-manager.backupFileExtension = "hmbak";
                  home-manager.extraSpecialArgs = {
                    inherit unstable autopkgs mcppkgs;
                    hostName = name;
                  };
                  home-manager.sharedModules = [
                    nixvim.homeModules.nixvim
                    vicinae.homeManagerModules.default
                  ];
                })
              ]
              ++ sharedModules;
          };
        };

      # Build all machines
      machines = map buildMachine validMachines;

      # Convert to attribute set and split by OS type
      machineAttrs = builtins.listToAttrs machines;

      # Split configurations using the same metadata used to build them.
      filterSystems = systemSuffix:
        nixpkgs.lib.filterAttrs
          (name: _:
            nixpkgs.lib.hasSuffix systemSuffix (machineMetadata name).system
          )
          machineAttrs;

      # Split by OS type
      nixosConfigs = filterSystems "-linux";
      darwinConfigs = filterSystems "-darwin";
    in
    let
      # Function to create case-insensitive aliases for configurations
      createCaseInsensitiveAliases = configs:
        let
          # Original configurations
          original = configs;

          # Create aliases with different case variations
          createAliases = name: value:
            let
              # Convert to lowercase and uppercase
              lowerName = nixpkgs.lib.strings.toLower name;
              upperName = nixpkgs.lib.strings.toUpper name;
              capitalizedName = nixpkgs.lib.strings.toUpper (builtins.substring 0 1 lowerName) + builtins.substring 1 (builtins.stringLength lowerName) lowerName;

              # Create aliases if they're different from the original name
              aliases = builtins.listToAttrs (
                builtins.filter (x: x.name != name) [
                  { inherit name; inherit value; }
                  { name = lowerName; inherit value; }
                  { name = upperName; inherit value; }
                  { name = capitalizedName; inherit value; }
                ]
              );
            in
            aliases;

          # Create aliases for all configurations
          allAliases = builtins.mapAttrs createAliases original;

          # Merge all aliases
          merged = builtins.foldl' (acc: aliases: acc // aliases) { } (builtins.attrValues allAliases);
        in
        original // merged;

      # Apply case-insensitive aliases
      nixosConfigsWithAliases = createCaseInsensitiveAliases nixosConfigs;
      darwinConfigsWithAliases = createCaseInsensitiveAliases darwinConfigs;
    in
    {
      # Expose our library for other flakes to use
      lib = {
        autoDiscovery = import ./lib/auto-discovery.nix { inherit (nixpkgs) lib; };
      };

      # System configurations with case-insensitive aliases
      nixosConfigurations = nixosConfigsWithAliases;
      darwinConfigurations = darwinConfigsWithAliases;
    };
}
# vim: set tabstop=2 softtabstop=2 shiftwidth=2 expandtab
