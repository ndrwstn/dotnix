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
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Disabling background services for Zoom and Google apps..."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Disable user-level services (can be done without sudo)
    launchctl disable gui/$(id -u)/us.zoom.updater 2>/dev/null && \
      echo "✓ Disabled: us.zoom.updater" || echo "  (us.zoom.updater already disabled or not found)"
    
    launchctl disable gui/$(id -u)/us.zoom.updater.login.check 2>/dev/null && \
      echo "✓ Disabled: us.zoom.updater.login.check" || echo "  (us.zoom.updater.login.check already disabled or not found)"
    
    launchctl disable gui/$(id -u)/com.google.keystone.agent 2>/dev/null && \
      echo "✓ Disabled: com.google.keystone.agent" || echo "  (com.google.keystone.agent already disabled or not found)"
    
    launchctl disable gui/$(id -u)/com.google.keystone.xpcservice 2>/dev/null && \
      echo "✓ Disabled: com.google.keystone.xpcservice" || echo "  (com.google.keystone.xpcservice already disabled or not found)"
    
    echo ""
    echo "Checking system-level daemons (requires sudo)..."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Check if system daemons are disabled (requires sudo to check)
    NEEDS_MANUAL=false
    
    # Check each system daemon
    if sudo launchctl print-disabled system 2>/dev/null | grep -q "us.zoom.ZoomDaemon"; then
      echo "✓ us.zoom.ZoomDaemon is disabled"
    else
      echo "✗ us.zoom.ZoomDaemon is NOT disabled"
      NEEDS_MANUAL=true
    fi
    
    if sudo launchctl print-disabled system 2>/dev/null | grep -q "com.google.GoogleUpdater.wake.system"; then
      echo "✓ com.google.GoogleUpdater.wake.system is disabled"
    else
      echo "✗ com.google.GoogleUpdater.wake.system is NOT disabled"
      NEEDS_MANUAL=true
    fi
    
    if sudo launchctl print-disabled system 2>/dev/null | grep -q "com.google.keystone.daemon"; then
      echo "✓ com.google.keystone.daemon is disabled"
    else
      echo "✗ com.google.keystone.daemon is NOT disabled"
      NEEDS_MANUAL=true
    fi
    
    if [ "$NEEDS_MANUAL" = true ]; then
      echo ""
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      echo "⚠️  MANUAL ACTION REQUIRED"
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      echo ""
      echo "Some system-level daemons are not disabled."
      echo "These require sudo privileges to disable."
      echo ""
      echo "Please run the following commands:"
      echo ""
      echo "  sudo launchctl disable system/us.zoom.ZoomDaemon"
      echo "  sudo launchctl disable system/com.google.GoogleUpdater.wake.system"
      echo "  sudo launchctl disable system/com.google.keystone.daemon"
      echo ""
      echo "Then reboot for changes to take full effect."
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    else
      echo ""
      echo "✓ All system daemons are disabled"
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    fi
    
    echo ""
    echo "Background service configuration complete."
  '';
}
