{ lib, pkgs, ... }:
{
  _astn.machine.role = lib.mkDefault "laptop";
  environment.systemPackages = with pkgs; [ jdk17 nmap nh ];
}
