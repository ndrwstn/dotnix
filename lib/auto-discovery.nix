{ lib }:
/*
  Auto-discovery functions for Nix configurations.
  
  These functions help discover and aggregate configurations from multiple
  directories and files, making it easier to maintain modular Nix configurations.
  
  Example usage:
  
  ```nix
  # Discover directories containing a specific file
  validMachines = autoDiscovery.discoverDirectories {
    basePath = ./machines;
    excludeNames = [ "common" ];
    filterPredicate = dir: builtins.pathExists (dir + "/configuration.nix");
  };
  
  # Discover and merge configurations from multiple directories
  mergedConfig = autoDiscovery.discoverAndMergeConfigs {
    directories = [ ./dir1 ./dir2 ];
    filePath = "config.nix";
    attributeName = "config";
    importArgs = { inherit lib; };
  };
  ```
*/
rec {
  # Directory-based discovery function
  discoverDirectories = { 
    basePath,
    filterPredicate ? (_: true),
    excludeNames ? [],
  }: 
    let
      # Get all directory names
      allDirs = builtins.attrNames (builtins.readDir basePath);
      
      # Apply exclusions and custom filter
      filteredDirs = builtins.filter 
        (name: 
          !(builtins.elem name excludeNames) && 
          (filterPredicate (basePath + "/${name}"))
        ) 
        allDirs;
    in
    filteredDirs;

  # File-based discovery function
  discoverAndMergeConfigs = {
    # Base directories to search in
    directories,
    # Relative path to the file within each directory
    filePath,
    # Attribute to extract from each file
    attributeName,
    # Arguments to pass to the imported module
    importArgs ? {},
    # Whether to warn about missing attributes
    warnOnMissingAttr ? true,
    # Default value to use if attribute is missing
    defaultValue ? {},
  }:
    let
      # Function to check if a file exists
      fileExists = dir: builtins.pathExists (dir + "/${filePath}");
      
      # Filter directories to those that have the file
      dirsWithFile = builtins.filter fileExists directories;
      
      # Import each file and extract the attribute
      importedConfigs = map 
        (dir: 
          let
            imported = import (dir + "/${filePath}") importArgs;
          in
          if builtins.hasAttr attributeName imported
          then imported.${attributeName}
          else 
            if warnOnMissingAttr 
            then lib.warn "File ${dir}/${filePath} doesn't contain a ${attributeName} attribute" defaultValue
            else defaultValue
        ) 
        dirsWithFile;
      
      # Merge all configurations
      mergedConfig = lib.mkMerge importedConfigs;
    in
    mergedConfig;
}