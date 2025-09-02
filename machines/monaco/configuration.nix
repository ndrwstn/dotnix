# machines/monaco/configuration.nix
{ config
, pkgs
, ...
}: {
  # Import secrets configuration
  imports = [
    ./secrets.nix
  ];
  # Machine metadata (used by flake.nix, does not affect system configuration)
  _astn.machineSystem = "aarch64-darwin";
  # Increase download-buffer to 2GB
  # Monaco has 64GB shared RAM.
  nix.settings.download-buffer-size = 2000000000;

  # Define hostname
  networking.hostName = "Monaco";

  # System packages
  environment = {
    systemPath = [
      "/opt/homebrew/bin"
      "/opt/homebrew/sbin"
    ];
    systemPackages = with pkgs; [
      coreutils
      gnused
      #      spacenavd # <- future spacenav support?
    ];
  };

  # homebrew
  homebrew.brews = [
    "m1ddc"
  ];

  # Set nix-darwin state version
  system.stateVersion = 4;
}
