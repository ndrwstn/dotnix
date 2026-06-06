# systems/nixos/broadcom.nix
# Shared Broadcom BCM4360 WiFi configuration for Mac hardware.
# Loaded by systems/nixos/default.nix — machines with Broadcom WiFi
# (silver, siberia) get this automatically.
{ config, lib, pkgs, ... }:

let
  # The broadcom-sta package name includes the version from nixpkgs.
  # CI (update-broadcom-pin.py) updates this pin when nixpkgs bumps the kernel.
  broadcomStaPin = "broadcom-sta-6.30.223.271-59-6.18.34";
in
{
  boot.extraModulePackages = [ config.boot.kernelPackages.broadcom_sta ];

  boot.kernelModules = [ "wl" ];

  boot.blacklistedKernelModules = [ "b43" "b43legacy" "ssb" "bcma" ];

  boot.extraModprobeConfig = ''
    # Blacklist b43 and related modules for BCM4360 WiFi chip
    # The b43 driver does not support BCM4360 (802.11ac) and creates
    # a race condition with the wl (broadcom_sta) driver
    blacklist b43
    blacklist b43legacy
    blacklist ssb
    blacklist bcma
  '';

  nixpkgs.config.permittedInsecurePackages = [
    broadcomStaPin
  ];
}
