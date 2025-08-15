# machines/monaco/secrets.nix
{ config, lib, pkgs, ... }:

{
  # Machine-specific secrets for Monaco
  # WiFi configuration is now handled in systems/common/sops.nix

  sops.secrets = {
    # Add Monaco-specific secrets here as needed
  };
}
