# systems/nixos/default.nix
# NixOS-specific configuration
{ config
, pkgs
, lib
, ...
}: {
  imports = [
    ./agenix.nix
    ./1password.nix
    ./hyprland.nix
  ];

  # Allow unfree packages (required for copilot-language-server)
  nixpkgs.config.allowUnfree = true;

  # Enable nix-ld for dynamically linked binaries (e.g., opencode from nixautopkgs)
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      # Core runtime libraries
      zlib
      zstd
      stdenv.cc.cc
      curl
      openssl

      # System libraries commonly needed
      attr
      libssh
      bzip2
      libxml2
      acl
      libsodium
      util-linux
      xz
      systemd

      # Additional libraries for bun-based applications
      brotli
      libffi
      gmp
      libGL
      vulkan-loader

      # X11/graphics support (for opencode-desktop)
      xorg.libX11
      xorg.libXext
      xorg.libXrender
      xorg.libXcursor
      xorg.libXfixes
      xorg.libXcomposite
      xorg.libXdamage
      xorg.libXrandr
      xorg.libxcb
      xorg.libXScrnSaver
      xorg.libxshmfence

      # Additional desktop dependencies
      gtk3
      glib
      dbus
      fontconfig
      freetype
      cairo
      pango
      gdk-pixbuf
      atk
      at-spi2-atk
      at-spi2-core
      cups
      nspr
      nss
      alsa-lib
      expat
      libdrm
      mesa
      libxkbcommon
      libepoxy
    ];
  };

  # Enable the X11 windowing system by default
  services.xserver = {
    enable = true;

    # Configure keymap (display manager moved to top-level)
    xkb = {
      layout = "us";
      variant = "";
    };
  };

  # GNOME desktop environment configuration (top-level services)
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # Exclude Seahorse to prevent SSH_ASKPASS interference
  environment.gnome.excludePackages = [ pkgs.seahorse ];

  # Enable dbus for zathura synctex
  services.dbus.enable = true;

  # Enable sound with pipewire
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  services.pulseaudio.enable = false;

  # Enable common services
  services = {
    # Enable printing support
    printing.enable = true;

    # Enable SSH daemon for agenix host key generation
    openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "no";
        AllowAgentForwarding = true;
      };
    };

    # Disable GNOME Keyring entirely to prevent SSH agent conflicts
    # This allows 1Password SSH agent to work without interference
    # Use mkForce to override the GNOME desktop manager's automatic enablement
    gnome.gnome-keyring.enable = lib.mkForce false;

    # Syncthing is configured per-user via home-manager

    # Enable iSCSI support
    openiscsi = {
      enable = true;
      name = "iqn.2025-01.us.impetuo.${config.networking.hostName}";
    };
  };

  systemd.services.brother-mfc-l8900 = {
    description = "Configure Brother MFC-L8900 printer";
    after = [ "cups.service" "agenix.service" ];
    requires = [ "cups.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";
    script = ''
      if [ ! -f "/run/agenix/general" ]; then
        echo "Printer secret /run/agenix/general not found; skipping printer setup."
        exit 0
      fi

      printerUri="$(${pkgs.jq}/bin/jq -r '.printers.brother_mfc_l8900.uri' /run/agenix/general)"
      if [ -z "$printerUri" ] || [ "$printerUri" = "null" ]; then
        echo "Printer URI not found in /run/agenix/general; skipping printer setup."
        exit 0
      fi

      ${pkgs.cups}/bin/lpadmin -p "Brother_MFC_L8900" -v "$printerUri" -m everywhere -E
      ${pkgs.cups}/bin/lpadmin -d "Brother_MFC_L8900"
    '';
  };

  # Disable GNOME's GCR SSH agent to prevent SSH_AUTH_SOCK override
  # This allows 1Password SSH agent to work properly
  environment.variables = {
    GSM_SKIP_SSH_AGENT_WORKAROUND = "1";
    # Prevent Seahorse from setting SSH_ASKPASS and interfering with 1Password
    SSH_ASKPASS = lib.mkForce "";
  };

  # Enable networking
  networking = {
    networkmanager.enable = true;

    # Enable firewall with Syncthing ports
    # Syncthing requires these ports for device discovery and synchronization
    firewall = {
      enable = true; # Explicitly enable firewall (default in NixOS)
      allowedTCPPorts = [
        22000 # Syncthing sync protocol (TCP)
      ];
      allowedUDPPorts = [
        22000 # Syncthing sync protocol (QUIC/UDP) 
        21027 # Syncthing local discovery broadcasts
      ];
    };
  };

  # Set your time zone
  time.timeZone = "America/New_York";

  # Select internationalization properties
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  #
  hardware = {
    logitech.wireless = {
      enable = true;
      enableGraphical = true;
    };
    rtl-sdr.enable = true;
  };

  #
  environment.systemPackages = with pkgs; [
    solaar
    usbutils

  ];

  # Ensure ClamAV database directory exists with proper permissions
  systemd.tmpfiles.rules = [
    "d /home/austin/.local/share/clamav 0755 austin users -"
  ];
}
