# Common user configurations
{ config, pkgs, lib, ... }:

{
  programs.zsh.enable = true;
  
  users.users = {
    austin = {
      isNormalUser = true;
      description = "Andrew Austin";
      extraGroups = [ "networkmanager" "wheel" "disk" ];
      shell = pkgs.zsh;
    };

    jessica = {
      isNormalUser = true;
      description = "Jessica Hirschhorn";
      extraGroups = [ "networkmanager" ];
    };
  };
}
