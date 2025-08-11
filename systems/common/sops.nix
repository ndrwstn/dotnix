# systems/common/sops.nix
{ config, lib, pkgs, ... }:

{
  # Common sops configuration for all systems
  sops = {
    # Default age key file location
    age.keyFile = "/var/lib/sops-nix/key.txt";
    
    # Default secrets directory
    defaultSecretsDir = ./secrets;
    
    # Default sops file
    defaultSopsFile = ./secrets/common.yaml;
    
    # Default sops format
    defaultSopsFormat = "yaml";
  };
}