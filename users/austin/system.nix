# users/austin/system.nix
# System-level account declaration for Austin.
{ pkgs, lib, ... }:
{
  # The secret module is always composed with Austin's system account, but its
  # payload declarations are role-gated inside users/austin/secrets.nix.
  imports = [ ./secrets.nix ];

  programs.zsh.enable = true;

  users.users.austin = {
    description = "Andrew Austin";
    shell = pkgs.zsh;
  } // lib.optionalAttrs (!pkgs.stdenv.hostPlatform.isDarwin) {
    isNormalUser = true;
    extraGroups = [ "networkmanager" "wheel" "disk" "plugdev" ];
    home = "/home/austin";
    hashedPassword = "$6$5PZLg16IXRSJaLiI$bU8OB6wng7ZvQcrkpX/x5pjX2GegtYN.YUIAibPvAtVq/nyGwfjLyGwV5GR2LCnEqytFzxxer6.fhAhO7G8lD1";
  } // lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
    home = "/Users/austin";
  };
}
