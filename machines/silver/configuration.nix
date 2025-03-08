# Machine-specific configuration for Silver
{
  config,
  pkgs,
  ...
}: {
  # Increase download-buffer to 1GB
  # Rebuilds on Silver should be an exclusive activity
  nix.settings.download-buffer-size = 1000000000;

  # Use the systemd-boot EFI boot loader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Define hostname
  networking.hostName = "Silver";

  # Enable webcam support
  hardware.facetimehd.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  system.stateVersion = "24.05";
}
