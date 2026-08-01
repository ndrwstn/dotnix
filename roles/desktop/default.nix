{ lib, pkgs, ... }:
{
  _astn.machine.role = lib.mkDefault "desktop";
  environment.systemPackages = with pkgs; [ jdk17 nmap nh ];
}
