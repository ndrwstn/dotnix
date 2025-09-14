# users/austin/atuin.nix - Atuin shell history sync configuration with per-machine secrets
{ config, lib, pkgs, hostName ? "unknown", ... }:

let
  # Use the hostName parameter passed from flake, normalize to lowercase
  machineName = lib.toLower hostName;

  # Path to the JSON secret file (provided by agenix)
  secretPath = "/run/agenix/atuin";

  # Directory for extracted secrets
  extractDir = "${config.home.homeDirectory}/.config/atuin";

  # Check if current machine is configured by checking if secrets exist
  isMachineConfigured = true; # Will be validated at runtime by checking secret files

  # Structured Atuin configuration data
  atuinConfig = {
    # Sync configuration
    sync_address = "https://atuin.impetuo.us";
    sync_frequency = "10m";

    # Encryption key path
    key_path = "${extractDir}/key";

    # Store configuration
    db_path = "${config.home.homeDirectory}/.local/share/atuin/history.db";
    record_store_path = "${config.home.homeDirectory}/.local/share/atuin/records";

    # Search configuration
    search_mode = "fuzzy";
    filter_mode = "global";

    # UI configuration
    inline_height = 0;
    show_preview = true;
    show_help = true;
    exit_mode = "return-original";
    word_jump_mode = "emacs";
    word_chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";

    # History configuration
    history_filter = [
      # Security-sensitive commands
      "^age "
      "^age-keygen"
      "^agenix "
      "^pass "
      "^gpg "
      "^gpg2 "
      "^ssh-keygen"
      "^openssl "
      "^vault "
      "^op "
      "^bw "
      # Authentication tokens
      ".*[Tt][Oo][Kk][Ee][Nn].*"
      ".*[Aa][Pp][Ii][-_]?[Kk][Ee][Yy].*"
      ".*[Ss][Ee][Cc][Rr][Ee][Tt].*"
      ".*[Pp][Aa][Ss][Ss][Ww][Oo][Rr][Dd].*"
      # Environment variables with secrets
      "export.*[Tt][Oo][Kk][Ee][Nn]"
      "export.*[Kk][Ee][Yy]"
      "export.*[Ss][Ee][Cc][Rr][Ee][Tt]"
      "export.*[Pp][Aa][Ss][Ss]"
    ];

    # Other settings
    auto_sync = true;
    update_check = false;
    sync_on_exit = true;
    enter_accept = true;

    # Daemon configuration
    daemon = {
      enabled = true;
      sync_frequency = 600;
    };
  };

  # TOML format generator
  tomlFormat = pkgs.formats.toml { };
  configFile = tomlFormat.generate "config.toml" atuinConfig;

  # Environment variables file content
  envFileContent = ''
    # Atuin environment variables
    export ATUIN_KEY_FILE="${extractDir}/key"
    export ATUIN_SYNC_ADDRESS="https://atuin.impetuo.us"
  '';

  # Early key extraction script - runs before installPackages
  extractKeyScript = pkgs.writeShellScript "extract-atuin-key" ''
    set -euo pipefail
    echo "Early Atuin key extraction"
    
    # Check if secret file exists
    if [[ ! -f "${secretPath}" ]]; then
      echo "No atuin secret found at ${secretPath}"
      exit 0
    fi
    
    # Create extraction directory
    mkdir -p "${extractDir}"
    chmod 700 "${extractDir}"
    
    # Extract only the key
    ${pkgs.jq}/bin/jq -r '.key // empty' "${secretPath}" > "${extractDir}/key" 2>/dev/null || {
      echo "Error: Failed to extract Atuin key from secret"
      exit 1
    }
    
    # Set appropriate permissions
    chmod 600 "${extractDir}/key"
    
    # Validate key exists and is not empty
    ATUIN_KEY=$(cat "${extractDir}/key" 2>/dev/null || echo "")
    if [[ -z "$ATUIN_KEY" ]]; then
      echo "Error: Atuin encryption key is empty"
      exit 1
    fi
    
    echo "Atuin key extracted early"
  '';

  # Later setup script - extract session token if needed
  setupAtuinScript = pkgs.writeShellScript "setup-atuin" ''
    set -euo pipefail

    echo "Setting up additional Atuin secrets"

    # Check if secret file exists
    if [[ ! -f "${secretPath}" ]]; then
      echo "Warning: Atuin secret file not found at ${secretPath}"
      echo "Skipping additional Atuin configuration"
      exit 0
    fi

    # Ensure extraction directory exists
    mkdir -p "${extractDir}"
    chmod 700 "${extractDir}"

    # Extract session token if present
    ${pkgs.jq}/bin/jq -r '.session // empty' "${secretPath}" > "${extractDir}/session" 2>/dev/null || true

    # Set appropriate permissions for session file if it exists
    if [[ -f "${extractDir}/session" ]]; then
      chmod 600 "${extractDir}/session"
    fi

    echo "Additional Atuin secrets setup complete"
  '';

  # Atuin configuration directory
  atuinConfigDir = "${config.home.homeDirectory}/.config/atuin";

  # Atuin shell integration for zsh - key guaranteed to exist
  atuinZshIntegration = ''
    # Source Atuin environment (key guaranteed to exist)
    if [[ -f "${atuinConfigDir}/env.sh" ]]; then
      source "${atuinConfigDir}/env.sh"
    fi
    
    # Initialize Atuin directly
    if command -v atuin &> /dev/null; then
      eval "$(atuin init zsh)"
    fi
  '';

  # Atuin shell integration for bash - key guaranteed to exist
  atuinBashIntegration = ''
    # Source Atuin environment (key guaranteed to exist)
    if [[ -f "${atuinConfigDir}/env.sh" ]]; then
      source "${atuinConfigDir}/env.sh"
    fi
    
    # Initialize Atuin directly
    if command -v atuin &> /dev/null; then
      eval "$(atuin init bash)"
    fi
  '';

in
{
  # Home Manager configuration
  home = {
    # Install Atuin package
    packages = lib.mkIf isMachineConfigured (with pkgs; [
      atuin
    ]);

    # Place environment variables file using Home Manager
    file.".config/atuin/env.sh" = lib.mkIf isMachineConfigured {
      text = envFileContent;
    };
  };

  # Early key extraction - runs before installPackages and writeBoundary
  home.activation.setupAtuinKeyEarly = lib.mkIf isMachineConfigured (
    lib.hm.dag.entryBefore [ "writeBoundary" ] ''
      ${extractKeyScript}
    ''
  );

  # Later setup for additional secrets - runs after writeBoundary
  home.activation.setupAtuin = lib.mkIf isMachineConfigured (lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${setupAtuinScript}
  '');

  # Place Atuin configuration file using Home Manager
  xdg.configFile."atuin/config.toml" = lib.mkIf isMachineConfigured {
    source = configFile;
  };

  # Add Atuin integration to shells
  programs.zsh = lib.mkIf (isMachineConfigured && config.programs.zsh.enable) {
    initExtra = lib.mkAfter atuinZshIntegration;
  };

  programs.bash = lib.mkIf (isMachineConfigured && config.programs.bash.enable) {
    initExtra = lib.mkAfter atuinBashIntegration;
  };

  # Create systemd service for Atuin daemon (Linux only)
  systemd.user.services.atuin-daemon = lib.mkIf (isMachineConfigured && pkgs.stdenv.isLinux) {
    Unit = {
      Description = "Atuin shell history sync daemon";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };

    Service = {
      Type = "simple";
      ExecStart = "${pkgs.atuin}/bin/atuin daemon";
      Restart = "on-failure";
      RestartSec = "10s";
      Environment = [
        "HOME=${config.home.homeDirectory}"
        "ATUIN_KEY_FILE=${extractDir}/key"
      ];
    };

    Install = {
      WantedBy = [ "default.target" ];
    };
  };

  # Create launchd service for Atuin daemon (macOS only)
  launchd.agents.atuin-daemon = lib.mkIf (isMachineConfigured && pkgs.stdenv.isDarwin) {
    enable = true;
    config = {
      ProgramArguments = [
        "${pkgs.atuin}/bin/atuin"
        "daemon"
      ];
      EnvironmentVariables = {
        HOME = config.home.homeDirectory;
        ATUIN_KEY_FILE = "${extractDir}/key";
      };
      RunAtLoad = true;
      KeepAlive = {
        SuccessfulExit = false;
      };
      StandardOutPath = "/tmp/atuin-daemon.log";
      StandardErrorPath = "/tmp/atuin-daemon.error.log";
    };
  };

  # Warning messages
  warnings = lib.optional (!isMachineConfigured)
    "Atuin is disabled for machine '${machineName}' - machine-specific secret file not found";
}

# vim: set tabstop=2 softtabstop=2 shiftwidth=2 expandtab
