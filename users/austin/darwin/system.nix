# users/austin/darwin/system.nix
{ config
, pkgs
, ...
}: {
  system = {
    defaults = {
      dock = {
        tilesize = 16;
        persistent-apps = [
          "/System/Applications/Mail.app"
          "/Applications/Across.app"
          "/System/Applications/Calendar.app"
          "/Applications/Things3.app"
          "/System/Applications/Reminders.app"
          "/System/Applications/Messages.app"
          "/Applications/Safari.app"
          "/Applications/Ghostty.app"
          "/Applications/Nix Apps/Neovide.app"
          # "/System/Applications/iPhone Mirroring.app"
        ];
        persistent-others = [
          "/Users/austin/Downloads"
        ];
      };
      finder = {
        ShowPathbar = true;
        ShowStatusBar = true;
      };

      CustomUserPreferences = {
        "com.apple.finder" = { };

        # Finder Services blacklist (macOS reads this from the `pbs` domain).
        #
        # How to add another hidden service:
        # 1) Disable it once in macOS Services settings.
        # 2) Read the generated key with: `defaults read pbs NSServicesStatus`.
        # 3) Copy the full key string into this attrset and keep all booleans false.
        #
        # This is blacklist-only: unlisted/new services remain visible by default.
        "pbs" = {
          NSServicesStatus = {
            "com.apple.Terminal - New Terminal at Folder - newTerminalAtFolder" = {
              enabled_context_menu = false;
              enabled_services_menu = false;
              presentation_modes = {
                ContextMenu = false;
                ServicesMenu = false;
              };
            };
            "com.apple.Terminal - New Terminal Tab at Folder - newTerminalAtFolder" = {
              enabled_context_menu = false;
              enabled_services_menu = false;
              presentation_modes = {
                ContextMenu = false;
                ServicesMenu = false;
              };
            };
            "com.apple.FolderActionsSetup - Folder Actions Setup - openFilesFromPasteboard" = {
              enabled_context_menu = false;
              enabled_services_menu = false;
              presentation_modes = {
                ContextMenu = false;
                ServicesMenu = false;
              };
            };
            "mega.mac - MEGA - handleItems" = {
              enabled_context_menu = false;
              enabled_services_menu = false;
              presentation_modes = {
                ContextMenu = false;
                ServicesMenu = false;
              };
            };
            "net.sourceforge.skim-app.skim - Show Skim Notes - openNotesDocumentFromURLOnPboard" = {
              enabled_context_menu = false;
              enabled_services_menu = false;
              presentation_modes = {
                ContextMenu = false;
                ServicesMenu = false;
              };
            };
            "net.sourceforge.skim-app.skim - Print File with Skim - printDocumentPanelFromURLOnPboard" = {
              enabled_context_menu = false;
              enabled_services_menu = false;
              presentation_modes = {
                ContextMenu = false;
                ServicesMenu = false;
              };
            };
            "net.sourceforge.skim-app.skim - Print File with Skim… - printDocumentFromURLOnPboard" = {
              enabled_context_menu = false;
              enabled_services_menu = false;
              presentation_modes = {
                ContextMenu = false;
                ServicesMenu = false;
              };
            };
          };
        };
        "com.apple.desktopservices" = {
          DSDontWriteNetworkStores = true;
          DSDontWriteUSBStores = true;
        };
        "com.apple.AdLib" = {
          allowApplePersonalizedAdvertising = false;
        };
        "com.apple.screensaver" = {
          askForPassword = 1;
          askForPasswordDelay = 10;
        };
      };
    };
  };
}
