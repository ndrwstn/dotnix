# systems/darwin/sops.nix
{ config, lib, pkgs, ... }:

{
  # Darwin-specific sops configuration
  # Since sops-nix doesn't have native Darwin support at the system level,
  # we rely on home-manager's sops module for user secrets

  config = {
    # Add sops-related packages
    environment.systemPackages = with pkgs; [
      sops
      age
    ];

    # Create necessary directories via launchd
    launchd.daemons.sops-nix-setup = {
      command = ''
        mkdir -p /var/lib/sops-nix
        chmod 700 /var/lib/sops-nix
      '';
      serviceConfig = {
        RunAtLoad = true;
        StandardOutPath = "/var/log/sops-nix-setup.log";
        StandardErrorPath = "/var/log/sops-nix-setup.err";
      };
    };
  };
}
