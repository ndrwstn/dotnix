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
  # Increase download-buffer to 1GB
  # Rebuilds on Silver should be an exclusive activity
  nix.settings.download-buffer-size = 1000000000;

  # Allow the insecure broadcom-sta package for WiFi
  nixpkgs.config.permittedInsecurePackages = [
    "broadcom-sta-6.30.223.271-57-6.12.48"
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

  # Enable webcam support
  hardware.facetimehd.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  system.stateVersion = "24.05";
}
