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
  # Function to determine system type for a machine
  extractSystemType = { 
    # Machine name
    name,
    # Base path to machines directory
    machinesPath ? ./machines,
    # Default system type if cannot be determined
    defaultSystemType ? "x86_64-linux",
  }:
    let
      # Path to configuration.nix
      configPath = machinesPath + "/${name}/configuration.nix";
      hasConfig = builtins.pathExists configPath;
      
      # Path to system.nix (for backward compatibility)
      systemNixPath = machinesPath + "/${name}/system.nix";
      hasSystemNix = builtins.pathExists systemNixPath;
      
      # Try to extract system type from configuration.nix comment
      systemTypeFromComment = 
        if hasConfig then
          let
            # Read the file as text
            configText = builtins.readFile configPath;
            # Look for SYSTEM_TYPE comment pattern
            commentMatch = builtins.match ".*#[[:space:]]*SYSTEM_TYPE:[[:space:]]*([a-zA-Z0-9_-]+).*" configText;
          in
            if commentMatch != null then builtins.elemAt commentMatch 0
            else null
        else
          null;
      
      # Fall back to system.nix for backward compatibility
      systemTypeFromSystemNix = 
        if hasSystemNix then
          import systemNixPath
        else
          null;
    in
      # Priority: 1. Comment, 2. system.nix, 3. default
      if systemTypeFromComment != null then systemTypeFromComment
      else if systemTypeFromSystemNix != null then systemTypeFromSystemNix
      else defaultSystemType;

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
    # Debug mode
    debug ? false,
  }:
    let
      # Function to check if a file exists
      fileExists = dir: builtins.pathExists (dir + "/${filePath}");
      
      # Filter directories to those that have the file
      dirsWithFile = builtins.filter fileExists directories;
      
      # Debug output
      _ = if debug then builtins.trace "Directories with ${filePath}: ${builtins.toJSON dirsWithFile}" null else null;
      
      # Import each file and extract the attribute
      importedConfigs = map 
        (dir: 
          let
            fullPath = dir + "/${filePath}";
            imported = import fullPath importArgs;
            hasAttr = builtins.hasAttr attributeName imported;
            
            # Debug output
            _ = if debug then builtins.trace "Importing ${fullPath}, has ${attributeName}: ${builtins.toJSON hasAttr}" null else null;
          in
          if hasAttr
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