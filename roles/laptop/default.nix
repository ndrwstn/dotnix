{ lib, pkgs, ... }:
{
  _astn.machine.role = lib.mkDefault "laptop";
  environment.systemPackages = with pkgs; [ jdk21 nmap nh ];
}
