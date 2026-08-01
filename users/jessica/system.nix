# users/jessica/system.nix
# System-level account declaration for Jessica.
{ pkgs, lib, ... }:
{
  users.users.jessica = {
    description = "Jessica Hirschhorn";
    home =
      if pkgs.stdenv.hostPlatform.isDarwin
      then "/Users/jessica"
      else "/home/jessica";
  } // lib.optionalAttrs (!pkgs.stdenv.hostPlatform.isDarwin) {
    isNormalUser = true;
    extraGroups = [ "networkmanager" ];
    hashedPassword = "$6$CXDT2agbjBSyDEnL$VDtjFbPcD20UWSSOj/h2rrYq/SteAkYBZcQn2N7/8fQpgEJKkxR9MbGokLwUjWvslAcwRDIVUcyOg.0neMFMK1";
  };
}
