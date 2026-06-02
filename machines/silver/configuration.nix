# machines/silver/configuration.nix
{ config
, pkgs
, ...
}: {
  imports = [
    ./secrets.nix
  ];
  # Machine metadata (used by flake.nix, does not affect system configuration)
  _astn.machineSystem = "x86_64-linux";
  _astn.machine.windowManagers = [ "gnome" "hyprland" ];

  _astn.presets = {
    gui.enable = true;
    graphics.enable = true;
    maker.enable = true;
    recording.enable = true;
    office.enable = true;
    radio.enable = true;
  };

  # Increase download-buffer to 1GB
  # Rebuilds on Silver should be an exclusive activity
  nix.settings.download-buffer-size = 1000000000;

  # Allow the insecure broadcom-sta package for WiFi
  nixpkgs.config.permittedInsecurePackages = [
    "broadcom-sta-6.30.223.271-59-6.18.33"
  ];

  # Use new OpenGL renderer on old MacBook Pro
  environment.variables = {
    GSK_RENDERER = "ngl";
  };
  # Use the systemd-boot EFI boot loader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Define hostname
  networking.hostName = "Silver";

  # Laptop lid behavior: suspend-then-hibernate, ignore when docked
  # This saves battery by hibernating after 30 minutes if left closed.
  # On external power: same behavior (in case it's unplugged while closed).
  # Docked: lid close does nothing (for external monitor use).
  services.logind.settings.Login = {
    HandleLidSwitch = "suspend-then-hibernate";
    HandleLidSwitchExternalPower = "suspend-then-hibernate";
    HandleLidSwitchDocked = "ignore";
    HandlePowerKey = "suspend";
  };

  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  # Enable webcam support
  hardware.facetimehd.enable = true;

  # Docker configuration
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;

    # Use NixOS auto-prune (correct syntax)
    autoPrune = {
      enable = true;
      dates = "daily";
    };

    # Valid daemon settings only
    daemon.settings = {
      log-driver = "journald";
      storage-driver = "overlay2";
    };
  };

  # Add austin to docker group for Docker access
  users.users.austin.extraGroups = [ "docker" ];

  # Docker Compose support
  environment.systemPackages = with pkgs; [
    docker-compose
  ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  system.stateVersion = "24.05";

  # ACPI wake source fix for MacBookPro11,1
  # Disables XHC1 (USB 3.0) and LID0 (lid sensor) wake triggers to prevent
  # the spurious 36-38 second immediate wake bug, allowing S3 deep sleep.
  # Without LID0 as a wake source, the lid alone won't wake the machine;
  # open the lid first, then press the power button to wake.
  systemd.services.fix-suspend-wake = {
    description = "Disable spurious ACPI wake sources for MacBookPro11,1";
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-modules-load.service" ];
    serviceConfig.Type = "oneshot";
    script = ''
      echo "XHC1" > /proc/acpi/wakeup
      echo "LID0" > /proc/acpi/wakeup
    '';
  };

  # Kernel parameters for Mac hardware firmware compatibility
  boot.kernelParams = [ "acpi_osi=Darwin" ];

  # Hibernate configuration
  security.protectKernelImage = false;
  boot.resumeDevice = "/dev/disk/by-uuid/32d31193-f0e9-4a15-8ae4-fa7b35f543d5";

  # Suspend then hibernate after 30 minutes
  systemd.sleep.settings.Sleep = {
    HibernateDelaySec = "1800";
  };

  # Post-resume WiFi module reload
  # If WiFi drops after suspend/resume (known issue with broadcom_sta/wl),
  # uncomment the block below to force-reload the module on every resume.
  # powerManagement.resumeCommands = ''
  #   ${pkgs.kmod}/bin/modprobe -r wl || true
  #   sleep 1
  #   ${pkgs.kmod}/bin/modprobe wl || true
  # '';
}
