# SSH configuration data for austin user
# This file contains all SSH-related data in a structured format
{
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
  sshMatches = [
    {
      condition = "Host monaco.impetuo.us";
      config = {
        HostName = "monaco.impetuo.us";
        User = "austin";
        Port = 22;
      };
    }
    {
      condition = "Host silver.impetuo.us";
      config = {
        HostName = "silver.impetuo.us";
        User = "austin";
        Port = 22;
      };
    }
    {
      condition = "Host plutonium.impetuo.us";
      config = {
        HostName = "plutonium.impetuo.us";
        User = "austin";
        Port = 22;
      };
    }
    {
      condition = "Host molybdenum.impetuo.us";
      config = {
        HostName = "molybdenum.impetuo.us";
        User = "austin";
        Port = 22;
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
}
