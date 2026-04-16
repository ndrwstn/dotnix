# users/austin/Documents/90__CONFIG/NIX/users/austin/darwin/keyboard.nix
# Comprehensive macOS System Keyboard Shortcuts Configuration
# 
# This file manages macOS system-wide keyboard shortcuts via home-manager's
# targets.darwin.defaults module, which writes to com.apple.symbolichotkeys.
#
# TODO: Migrate to nix-darwin's system.keyboard.shortcuts when PR #1741 merges:
# https://github.com/nix-darwin/nix-darwin/pull/1741
#
# Reference for symbolic hotkey IDs:
# https://github.com/nix-darwin/nix-darwin/issues/518
# https://github.com/andyjakubowski/dotfiles
# https://stackoverflow.com/questions/866056
#
# To find current settings on your system:
#   defaults read com.apple.symbolichotkeys AppleSymbolicHotKeys
#
# To apply changes without logout:
#   /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
#
# NOTE: Only Mission Control shortcuts and Cmd-tilde are kept enabled.
#       Everything else is explicitly disabled.
#
{ config, lib, pkgs, ... }:

{
  targets.darwin.defaults."com.apple.symbolichotkeys" = {
    AppleSymbolicHotKeys = {
      # ============================================================================
      # DOCK (DISABLED)
      # ============================================================================
      "52" = { enabled = false; }; # Turn Dock Hiding On/Off (⌥⌘D)

      # ============================================================================
      # FOCUS & NAVIGATION (DISABLED except 27)
      # ============================================================================
      "7" = { enabled = false; }; # Move focus to menu bar (⌃F2)
      "8" = { enabled = false; }; # Move focus to Dock (⌃F3)
      "9" = { enabled = false; }; # Move focus to active/next window (⌃F4)
      "10" = { enabled = false; }; # Move focus to toolbar (⌃F5)
      "11" = { enabled = false; }; # Move focus to floating window (⌃F6)
      # "27" = { enabled = true; }; # Move focus to next window (⌘`) - KEPT ENABLED
      "51" = { enabled = false; }; # Move focus to window drawer (⌥⌘')

      # ============================================================================
      # SCREENSHOTS (ALL DISABLED)
      # ============================================================================
      "28" = { enabled = false; }; # Save picture of screen (⇧⌘3)
      "29" = { enabled = false; }; # Copy picture of screen (^⇧⌘3)
      "30" = { enabled = false; }; # Save picture of selected area (⇧⌘4)
      "31" = { enabled = false; }; # Copy picture of selected area (^⇧⌘4)
      "184" = { enabled = false; }; # Screenshot and recording options (⇧⌘5)
      "181" = { enabled = false; }; # Save Touch Bar screenshot (⇧⌘6)
      "182" = { enabled = false; }; # Copy Touch Bar screenshot (^⇧⌘6)

      # ============================================================================
      # ACCESSIBILITY (ALL DISABLED)
      # ============================================================================
      "15" = { enabled = false; }; # Turn zoom on/off (⌥⌘8)
      "17" = { enabled = false; }; # Zoom in (⌥⌘=)
      "19" = { enabled = false; }; # Zoom out (⌥⌘-)
      "21" = { enabled = false; }; # Invert colors (^⌥⌘8)
      "25" = { enabled = false; }; # Increase contrast (^⌥⌘.)
      "26" = { enabled = false; }; # Decrease contrast (^⌥⌘,)
      "59" = { enabled = false; }; # Turn VoiceOver on/off (⌘F5)

      # ============================================================================
      # MISSION CONTROL & SPACES (ENABLED - kept as defaults)
      # ============================================================================
      # "32" = { enabled = true; };  # Mission Control (⌃↑)
      # "34" = { enabled = true; };  # Mission Control (variant)
      # "36" = { enabled = true; };  # Show Desktop (F11)
      # "37" = { enabled = true; };  # Show Desktop (variant)
      # "79" = { enabled = true; };  # Move left a space (⌃←)
      # "80" = { enabled = true; };  # Move left a space (variant)
      # "81" = { enabled = true; };  # Move right a space (⌃→)
      # "82" = { enabled = true; };  # Move right a space (variant)
      # "118" = { enabled = true; }; # Switch to Desktop 1 (⌃1)
      # "119" = { enabled = true; }; # Switch to Desktop 2 (⌃2)
      # "120" = { enabled = true; }; # Switch to Desktop 3 (⌃3)
      # "121" = { enabled = true; }; # Switch to Desktop 4 (⌃4)

      # ============================================================================
      # SPOTLIGHT (ALL DISABLED)
      # ============================================================================
      "64" = { enabled = false; }; # Show Spotlight search (⌘Space)
      "65" = { enabled = false; }; # Show Finder search window (^⇧Space)

      # ============================================================================
      # INPUT SOURCES (ALL DISABLED)
      # ============================================================================
      "60" = { enabled = false; }; # Previous input source (^Space)
      "61" = { enabled = false; }; # Next input source (⌥⌘Space)
    };
  };
}
# NOTES:
# - Window tiling shortcuts (Sequoia 15+) are menu-based, NOT symbolic hotkeys.
#   Disable via System Settings > Keyboard > App Shortcuts or NSUserKeyEquivalents.
# - "Show Accessibility controls" (⌥⌘F5) is an App Shortcut, not a symbolic hotkey.
# - Changes require logout/login or: activateSettings -u
# - Verify current settings: defaults read com.apple.symbolichotkeys AppleSymbolicHotKeys
