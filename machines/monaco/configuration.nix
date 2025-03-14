# machines/plutonium/configuration.nix
{
  config,
  pkgs,
  ...
}: {
  # Define hostname
  networking.hostName = "Monaco";

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # System packages
  environment.systemPackages = with pkgs; [
    coreutils
    gnused
  ];

  # Set nix-darwin state version
  system.stateVersion = 4;
}

