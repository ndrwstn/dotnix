# SSH configuration for austin user - Combined data and configuration
# This file contains all SSH-related data and configuration logic in a single place
{ lib, pkgs, hostName ? "", ... }:

let
  # ============================================================================
  # SSH Configuration Data
  # ============================================================================

  # Machine definitions with their SSH public keys
  machines = {
    monaco = {
      key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEi5vWCZakanx3my3yk8XrGItqffYec/XKtLW+kbrlJ2";
      hostname = "monaco.impetuo.us";
      user = "austin";
      port = 22;
      capabilities = [ "setup-key" "ios-devices" ];
    };

    silver = {
      key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPltIgPNj7bpMDFuKQUmx+ZzwDBHOHFqLFokTTEeoOsb";
      hostname = "silver.impetuo.us";
      user = "austin";
      port = 22;
      capabilities = [ "setup-key" ];
    };

    plutonium = {
      key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDlZp70fv8pxvVtTTTx9juvvce/X1Ls3cUWR6l31WWQs";
      hostname = "plutonium.impetuo.us";
      user = "austin";
      port = 22;
      capabilities = [ "setup-key" ];
    };

    molybdenum = {
      key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINmELnQH/n96+5+eK3JPsDHG4QCY0BhtBalTVg0MPYG4";
      hostname = "molybdenum.impetuo.us";
      user = "austin";
      port = 22;
      capabilities = [ "setup-key" ];
    };
  };

  # Device keys (iOS devices, Windows machines, etc.)
  devices = {
    bradley = {
      key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHoANHywPMoqstT5RNJ/s1rd43C47Iw4gO6RRjLK7FLR";
      description = "iOS device - bradley";
    };

    halsey = {
      key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIm56by8poUWuitW20966Mjw+MiVowwtZQR39rbYASm1";
      description = "iOS device - halsey";
    };

    nimitz = {
      key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL5iqDoFpbUH1RmiCGLqfmXzjo1RBZePpZDXaF9bKF1Q";
      description = "iOS device - nimitz";
    };

    mckinley = {
      key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOzAvkC7u31iGU33SxdvhytEf+T3uqhxqFsK/9qZ0qt0";
      description = "Windows device - mckinley";
    };
  };

  # Universal setup key (deployed via agenix to machines with setup-key capability)
  setupKey = {
    description = "Universal setup private key for remote access";
    secretPath = "ssh-setup.age";
  };

  # Known hosts data (host keys for SSH client)
  knownHosts = {
    "monaco.impetuo.us" = {
      key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJSystV+gQ3/tiYxrk/Cmvr0WQBrz6UjA2cVwL8vxtgX";
      keyType = "ssh-ed25519";
    };

    "silver.impetuo.us" = {
      key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEEasqUb7EN/yKS02tfVNvz8nYzgOhw0DDLz/rTR86Nw";
      keyType = "ssh-ed25519";
    };

    "github.com" = {
      key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl";
      keyType = "ssh-ed25519";
    };
  };

  # Legacy VM configurations (if needed)
  legacyVMs = {
    # Example for future use:
    # old-vm = {
    #   hostname = "192.168.1.100";
    #   user = "root";
    #   port = 2222;
    #   keyType = "ssh-rsa";  # For older systems that don't support ed25519
    # };
  };

  # Special device configurations (3D printers, IoT devices, etc.)
  specialDevices = {
    # Example for devices that only support ssh-rsa:
    # printer3d = {
    #   hostname = "printer.local";
    #   user = "pi";
    #   port = 22;
    #   keyType = "ssh-rsa";
    #   description = "3D printer with ssh-rsa requirement";
    # };
  };

  # SSH client match configurations
  # This configuration solves the "SSH trying all keys" problem with 1Password by:
  # 1. Setting IdentitiesOnly yes globally to prevent SSH from trying all available keys
  # 2. Explicitly specifying IdentityFile for each host to use the current machine's key
  # 3. Using deployed public key files that 1Password can match to private keys
  # 4. Using deployed public keys for external services (gitea, github)
  # 5. Using physical setup key for goetz (bootstrap/setup scenarios)
  sshMatches = [
    # Nix machines - use current machine's public key file
    {
      condition = "Host monaco.impetuo.us";
      config = {
        HostName = "monaco.impetuo.us";
        User = "austin";
        Port = 22;
        IdentityFile = "~/.ssh/${lib.toLower hostName}.pub";
        IdentitiesOnly = "yes";
      };
    }
    {
      condition = "Host silver.impetuo.us";
      config = {
        HostName = "silver.impetuo.us";
        User = "austin";
        Port = 22;
        IdentityFile = "~/.ssh/${lib.toLower hostName}.pub";
        IdentitiesOnly = "yes";
      };
    }
    {
      condition = "Host plutonium.impetuo.us";
      config = {
        HostName = "plutonium.impetuo.us";
        User = "austin";
        Port = 22;
        IdentityFile = "~/.ssh/${lib.toLower hostName}.pub";
        IdentitiesOnly = "yes";
      };
    }
    {
      condition = "Host molybdenum.impetuo.us";
      config = {
        HostName = "molybdenum.impetuo.us";
        User = "austin";
        Port = 22;
        IdentityFile = "~/.ssh/${lib.toLower hostName}.pub";
        IdentitiesOnly = "yes";
      };
    }
    # External services - use deployed public keys
    {
      condition = "Host gitea.impetuo.us";
      config = {
        HostName = "gitea.impetuo.us";
        User = "git";
        Port = 22;
        IdentityFile = "~/.ssh/gitea.pub";
        IdentitiesOnly = "yes";
      };
    }
    {
      condition = "Host github.com";
      config = {
        HostName = "github.com";
        User = "git";
        Port = 22;
        IdentityFile = "~/.ssh/github.pub";
        IdentitiesOnly = "yes";
      };
    }
    # Physical setup key for bootstrap scenarios
    {
      condition = "Host goetz.impetuo.us";
      config = {
        HostName = "goetz.impetuo.us";
        User = "austin";
        Port = 22;
        IdentityFile = "~/.ssh/setup";
        IdentitiesOnly = "yes";
      };
    }
    # 1Password phantom path for nietzsche
    {
      condition = "Host nietzsche.impetuo.us";
      config = {
        HostName = "nietzsche.impetuo.us";
        User = "austin";
        Port = 22;
        IdentityFile = "~/.ssh/nietzsche-monaco";
        IdentitiesOnly = "yes";
      };
    }
  ];

  # Capability definitions
  capabilities = {
    setup-key = {
      description = "Machines that receive the universal setup private key";
      deploySecrets = [ "ssh-setup.age" ];
    };

    ios-devices = {
      description = "Machines that accept iOS device connections";
      authorizedKeys = [ "bradley" "halsey" "nimitz" "mckinley" ];
    };
  };

  # ============================================================================
  # Helper Functions
  # ============================================================================

  # Helper function to check if a machine has a specific capability
  hasCapability = capability: machine:
    lib.elem capability (machine.capabilities or [ ]);

  # Helper function to get current machine data
  getCurrentMachine = hostName:
    machines.${lib.toLower hostName} or null;

  # Generate authorized keys based on machine capabilities
  generateAuthorizedKeys = machine:
    let
      # Always include machine keys (for inter-machine communication)
      machineKeys = lib.mapAttrsToList (name: machineData: machineData.key) machines;

      # Add device keys if machine has ios-devices capability
      deviceKeys =
        if hasCapability "ios-devices" machine
        then lib.mapAttrsToList (name: deviceData: deviceData.key) devices
        else [ ];
    in
    machineKeys ++ deviceKeys;

  # Generate SSH client configuration from match rules
  generateSSHMatches = matches:
    lib.concatStringsSep "\n" (map
      (match: ''
        ${match.condition}
          ${lib.concatStringsSep "\n  " (lib.mapAttrsToList (key: value: "${key} ${toString value}") match.config)}
      '')
      matches);

  # Generate known_hosts content
  generateKnownHosts = hosts:
    lib.concatStringsSep "\n" (lib.mapAttrsToList
      (hostname: hostData:
        "${hostname} ${hostData.key}"
      )
      hosts);

  # ============================================================================
  # Computed Values
  # ============================================================================

  # Get current machine configuration
  currentMachine = getCurrentMachine hostName;

  # Determine authorized keys for this machine
  authorizedKeys =
    if currentMachine != null
    then generateAuthorizedKeys currentMachine
    else lib.mapAttrsToList (name: machineData: machineData.key) machines; # fallback to machine keys only

  # Note: Setup key deployment is handled at machine level via secrets.nix files
in
{
  # Note: agenix secrets are configured via age.secrets below, not via imports

  programs.ssh = {
    enable = true;

    # Use dual known_hosts files: writable for new hosts + Nix-managed (read-only)
    # Order matters: SSH writes to the first file, so put writable file first
    userKnownHostsFile = "~/.ssh/known_hosts ~/.ssh/known_hosts_nix";

    # Configure 1Password SSH agent for all platforms with IdentitiesOnly
    # This configuration prevents SSH from trying all available keys in 1Password,
    # which was causing authentication failures due to too many key attempts.
    # Instead, we explicitly specify which key to use for each host via IdentityFile.
    extraConfig = ''
      Host *
        # Use 1Password SSH agent for key management
        IdentityAgent ${
          if pkgs.stdenv.isDarwin 
          then "\"~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock\""
          else "~/.1password/agent.sock"
        }
        # Prevent SSH from trying all available keys - only use explicitly specified ones
        IdentitiesOnly yes
        # Terminal and security settings
        SetEnv TERM=xterm-256color
        StrictHostKeyChecking accept-new
      
      ${generateSSHMatches sshMatches}
    '';
  };

  # Deploy authorized_keys via home-manager (works on both Darwin and NixOS)
  home.file.".ssh/authorized_keys" = {
    text = lib.concatStringsSep "\n" authorizedKeys;
  };

  # Create Nix-managed known_hosts file (read-only)
  home.file.".ssh/known_hosts_nix" = {
    text = generateKnownHosts knownHosts;
  };

  # Deploy current machine's public key for SSH authentication  
  # This allows IdentityFile to reference a real file while using 1Password
  home.file.".ssh/${lib.toLower hostName}.pub" = lib.mkIf (currentMachine != null) {
    text = currentMachine.key; # The machine's public key from the machines definition
  };

  # Deploy public keys for external services
  # These are used with IdentitiesOnly to ensure only the correct key is tried
  home.file.".ssh/gitea.pub" = {
    text = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC80rsUP8S2W51b7xEjxIzZ6Wcdpwo0WTEKpu56EZpFM";
  };

  home.file.".ssh/github.pub" = {
    text = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG6/c2t60dTIt2Z9Nkfh1SU4oWqgCe3YLTYRslGbs91U";
  };

  # Create symlink to setup key for machines that have it deployed via agenix
  # This allows SSH config to reference ~/.ssh/setup while agenix deploys to /run/agenix/ssh-setup
  # Note: Using home.activation because /run/agenix/ssh-setup only exists at runtime, not build time
  home.activation.linkSetupKey = lib.mkIf (currentMachine != null && hasCapability "setup-key" currentMachine) (
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [ -f "/run/agenix/ssh-setup" ]; then
        $DRY_RUN_CMD ln -sf "/run/agenix/ssh-setup" "$HOME/.ssh/setup"
      fi
    ''
  );

  # Ensure writable known_hosts file exists for dynamic host entries
  home.activation.ensureWritableKnownHosts = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -f "$HOME/.ssh/known_hosts" ]; then
      $DRY_RUN_CMD touch "$HOME/.ssh/known_hosts"
    fi
  '';

  # Note: SSH setup key is deployed via machine-specific secrets.nix files
  # for machines with setup-key capability (monaco, silver, etc.)
}
