# systems/darwin/disable-background-services.nix
{ config, lib, pkgs, ... }: {
  # Disable unwanted background services for apps managed by Nix
  # These apps should only run when manually opened, no auto-updates

  # Method 1: Override user-level services with disabled versions
  launchd.user.agents."us.zoom.updater" = {
    serviceConfig = {
      Disabled = true;
      Label = "us.zoom.updater";
    };
  };

  launchd.user.agents."us.zoom.updater.login.check" = {
    serviceConfig = {
      Disabled = true;
      Label = "us.zoom.updater.login.check";
    };
  };

  launchd.user.agents."com.google.keystone.agent" = {
    serviceConfig = {
      Disabled = true;
      Label = "com.google.keystone.agent";
    };
  };

  launchd.user.agents."com.google.keystone.xpcservice" = {
    serviceConfig = {
      Disabled = true;
      Label = "com.google.keystone.xpcservice";
    };
  };

  # Method 2: Use activation scripts to disable services via launchctl
  system.activationScripts.postActivation.text = ''
    ANY_CHANGED=false
    NEEDS_MANUAL=false
    CHANGED_SERVICES=()

    # Disable user-level services (can be done without sudo)
    launchctl disable "gui/$(id -u)/us.zoom.updater" 2>/dev/null && \
      CHANGED_SERVICES+=("us.zoom.updater")
    
    launchctl disable "gui/$(id -u)/us.zoom.updater.login.check" 2>/dev/null && \
      CHANGED_SERVICES+=("us.zoom.updater.login.check")
    
    launchctl disable "gui/$(id -u)/com.google.keystone.agent" 2>/dev/null && \
      CHANGED_SERVICES+=("com.google.keystone.agent")
    
    launchctl disable "gui/$(id -u)/com.google.keystone.xpcservice" 2>/dev/null && \
      CHANGED_SERVICES+=("com.google.keystone.xpcservice")

    if [[ ''${#CHANGED_SERVICES[@]} -gt 0 ]]; then
      ANY_CHANGED=true
    fi
    
    # Check if system daemons are disabled (requires sudo to check)
    # Check each system daemon
    if ! sudo launchctl print-disabled system 2>/dev/null | grep -q "us.zoom.ZoomDaemon"; then
      echo "✗ us.zoom.ZoomDaemon is NOT disabled"
      NEEDS_MANUAL=true
    fi
    
    if ! sudo launchctl print-disabled system 2>/dev/null | grep -q "com.google.GoogleUpdater.wake.system"; then
      echo "✗ com.google.GoogleUpdater.wake.system is NOT disabled"
      NEEDS_MANUAL=true
    fi
    
    if ! sudo launchctl print-disabled system 2>/dev/null | grep -q "com.google.keystone.daemon"; then
      echo "✗ com.google.keystone.daemon is NOT disabled"
      NEEDS_MANUAL=true
    fi
    
    if [[ "$ANY_CHANGED" = true ]]; then
      echo "Disabled background services: $(IFS=", "; echo "''${CHANGED_SERVICES[*]}")"
    fi

    if [ "$NEEDS_MANUAL" = true ]; then
      echo "Manual action required: disable system daemons with sudo"
      echo "  sudo launchctl disable system/us.zoom.ZoomDaemon"
      echo "  sudo launchctl disable system/com.google.GoogleUpdater.wake.system"
      echo "  sudo launchctl disable system/com.google.keystone.daemon"
    fi
  '';
}
