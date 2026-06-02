# machines/molybdenum/configuration.nix
{ config
, pkgs
, ...
}: {
  # Import secrets configuration
  imports = [
    ./secrets.nix
  ];
  # Machine metadata (used by flake.nix, does not affect system configuration)
  _astn.machineSystem = "x86_64-linux";
  _astn.machine.windowManagers = [ "i3" ];

  _astn.presets = {
    graphics.enable = false;
    maker.enable = false;
    recording.enable = false;
    office.enable = false;
    radio.enable = false;
  };

  # Increase download-buffer to 1GB
  nix.settings.download-buffer-size = 1000000000;

  # Define hostname
  networking.hostName = "Molybdenum";

  # Laptop lid and power button behavior
  services.logind.settings.Login = {
    HandleLidSwitch = "suspend-then-hibernate";
    HandleLidSwitchExternalPower = "suspend-then-hibernate";
    HandleLidSwitchDocked = "ignore";
    HandlePowerKey = "suspend";
  };

  # Kernel parameters for nouveau resume stability (NVIDIA GT 330M)
  boot.kernelParams = [ "init_on_alloc=0" ];

  # Use the systemd-boot EFI boot loader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  system.stateVersion = "25.05";

  # Hibernate configuration
  security.protectKernelImage = false;
  boot.resumeDevice = "/dev/disk/by-uuid/8726af91-4af4-43fe-8a70-9af3dce337a4";

  # Suspend then hibernate after 30 minutes
  systemd.sleep.settings.Sleep = {
    HibernateDelaySec = "1800";
  };
}
