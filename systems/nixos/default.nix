# systems/nixos/default.nix
# NixOS-specific configuration
{ config
, pkgs
, lib
, inputs
, ...
}: {
  imports = [
    inputs.agenix.nixosModules.default
  ];
  # Enable the X11 windowing system by default
  services.xserver = {
    enable = true;

    # Enable the GNOME Desktop Environment
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;

    # Configure keymap
    xkb = {
      layout = "us";
      variant = "";
    };
  };

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
      };
    };

    # Syncthing is configured per-user via home-manager

    # Enable iSCSI support
    openiscsi = {
      enable = true;
      name = "iqn.2025-01.us.impetuo.${config.networking.hostName}";
    };
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
    inputs.agenix.packages.${pkgs.system}.default
  ];
}
