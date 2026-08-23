{ lib, pkgs, ... }:
{
  _astn.machine.role = lib.mkDefault "desktop";
  environment.systemPackages = with pkgs; [ jdk21 nmap nh ];
}
