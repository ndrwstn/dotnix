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

  # GUI-domain environment (PYTHONPATH + SSH_AUTH_SOCK) is provided via
  # nixdarwin.gui-environment LaunchAgent, bootstrapped into gui/<uid>/.
  # See the system.activationScripts entry in the system mkMerge below.

  # Apply the merged Homebrew config directly
  homebrew = mergedHomebrewConfig;

  # Apply the merged System defaults with primaryUser
  system = lib.mkMerge [
    mergedSystemDefaults
    { primaryUser = "austin"; }
    {
      activationScripts.postActivation.text = lib.mkAfter ''
                # Write nixdarwin.gui-environment plist for GUI-domain environment variables
                GUI_USER="austin"
                GUI_DOMAIN="gui/$(id -u "$GUI_USER")"
                PLIST_DIR="/Users/$GUI_USER/Library/LaunchAgents"
                PLIST_PATH="$PLIST_DIR/nixdarwin.gui-environment"

                sudo --user="$GUI_USER" -- mkdir -p "$PLIST_DIR"

                sudo --user="$GUI_USER" -- tee "$PLIST_PATH" >/dev/null <<'PLIST_EOF'
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>Label</key>
            <string>nixdarwin.gui-environment</string>
            <key>LimitLoadToSessionType</key>
            <string>Aqua</string>
            <key>EnvironmentVariables</key>
            <dict>
                <key>PYTHONPATH</key>
                <string>${lib.concatStringsSep ":" (map (pkg: "${pkg}/${pkgs.python311.sitePackages}") pyspacePkgs)}</string>
                <key>SSH_AUTH_SOCK</key>
                <string>/Users/austin/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock</string>
            </dict>
            <key>RunAtLoad</key>
            <true/>
        </dict>
        </plist>
        PLIST_EOF

                echo "Bootstrapping nixdarwin.gui-environment into $GUI_DOMAIN..." >&2
                launchctl bootstrap "$GUI_DOMAIN" "$PLIST_PATH" 2>/dev/null || true
      '';
    }
  ];
}
