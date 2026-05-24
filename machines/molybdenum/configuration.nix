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

  # Use the systemd-boot EFI boot loader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  system.stateVersion = "25.05";
}
