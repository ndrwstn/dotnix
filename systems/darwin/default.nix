# systems/darwin/default.nix
{ config
, pkgs
, lib
, inputs
, ...
}:
let
  # Import our auto-discovery library
  autoDiscovery = import ../../lib/auto-discovery.nix { inherit lib; };

  # Get list of user directories
  usersDir = ../../users;

  # Get all user directories
  userDirs = map (user: usersDir + "/${user}")
    (autoDiscovery.discoverDirectories {
      basePath = usersDir;
    });

  # Discover and merge homebrew configurations
  mergedHomebrewConfig = autoDiscovery.discoverAndMergeConfigs {
    directories = [ ./. ] ++ userDirs;
    filePath = "darwin/homebrew.nix";
    attributeName = "homebrew";
    importArgs = { inherit config pkgs lib; };
  };

  # Discover and merge system configurations
  mergedSystemDefaults = autoDiscovery.discoverAndMergeConfigs {
    directories = [ ./. ] ++ userDirs;
    filePath = "darwin/system.nix";
    attributeName = "system";
    importArgs = { inherit config pkgs lib; };
    warnOnMissingAttr = true;
    debug = true;
  };

  # Collect each Python module's site-packages as a separate PYTHONPATH entry.
  # We filter out the interpreter (python3) because its site-packages contains
  # sitecustomize.py and _sysconfigdata, which would override FreeCAD's conda
  # Python's sys.prefix/sys.executable and crash the app on startup.
  # Only packages with a pythonModule attribute are actual Python packages;
  # the interpreter itself lacks this attribute, so the filter excludes it.
  # Each individual package site-packages directory is clean (no sitecustomize.py).
  pyspacePkgs = builtins.filter (p: p ? pythonModule)
    (pkgs.python311Packages.requiredPythonModules [
      pkgs.python311Packages.pyspacemouse
    ]);
in
{
  # Import the apps modules and agenix configuration
  imports = [
    ./apps
    ./agenix.nix
    ./login-items.nix
    ./disable-background-services.nix
    ./printers.nix
  ];

  # any GUI apps must be added system-wide
  environment.systemPackages = [
    pkgs.neovide
  ];

  # Fix NIX_PATH for darwin systems
  nix.nixPath = [
    "nixpkgs=flake:nixpkgs"
  ];

  # Match nixbld GID across all Darwin systems
  ids.gids.nixbld = 350;

  # Allow unfree packages on Darwin systems
  nixpkgs.config.allowUnfree = true;

  # Apply pyspacemouse overlay (Darwin-only, contains .dylib paths;
  # NOT in overlays/default.nix which is used for Linux overlays only)
  nixpkgs.overlays = [ (import ../../overlays/pyspacemouse.nix) ];

  # Make pyspacemouse + transitive deps available to FreeCAD.app's Python 3.11
  # via PYTHONPATH. FreeCAD.app has disable-library-validation, allowing unsigned
  # Nix-built C extensions to load. SIP does NOT strip PYTHONPATH (only DYLD_*).
  # Takes effect after `darwin-rebuild switch` + logout/login.
  launchd.user.envVariables = {
    PYTHONPATH = map (pkg: "${pkg}/${pkgs.python311.sitePackages}") pyspacePkgs;
  };

  # Apply the merged Homebrew config directly
  homebrew = mergedHomebrewConfig;

  # Apply the merged System defaults with primaryUser
  system = lib.mkMerge [
    mergedSystemDefaults
    { primaryUser = "austin"; }
  ];
}
