# NixOS-specific configuration
{
  config,
  pkgs,
  lib,
  ...
}: {
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

    # Enable Syncthing
    syncthing.enable = true;

    # Enable iSCSI support
    openiscsi = {
      enable = true;
      name = "iqn.2025-01.us.impetuo.${config.networking.hostName}";
    };
  };

  # Enable networking
  networking = {
    networkmanager.enable = true;
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
  hardware.logitech.wireless = {
    enable = true;
    enableGraphical = true;
  };

  #
  environment.systemPackages = with pkgs; [
    solaar
  ];
}
