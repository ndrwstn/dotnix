# machines/monaco/configuration.nix
{ config
, pkgs
, ...
}: {
  # Increase download-buffer to 1GB
  # Monaco has 64GB shared RAM.
  nix.settings.download-buffer-size = 1000000000;

  # Match nixblg GID
  ids.gids.nixbld = 350;

  # Define hostname
  networking.hostName = "Monaco";

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

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
