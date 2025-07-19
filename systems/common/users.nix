# systems/common/users.nix
# Common user configurations
{ config
, pkgs
, lib
, ...
}: {
  programs.zsh.enable = true;

  users.users = lib.mkMerge [
    # Common user configuration
    {
      austin = {
        description = "Andrew Austin";
        shell = pkgs.zsh;
      };

      jessica = {
        description = "Jessica Hirschhorn";
      };
    }

    # NixOS-specific user configuration
    (lib.mkIf (!pkgs.stdenv.hostPlatform.isDarwin) {
      austin = {
        isNormalUser = true;
        # extraGroups = [ "networkmanager" "wheel" "disk" "plugdev" "dialout" ];
        extraGroups = [ "networkmanager" "wheel" "disk" "plugdev" ];
        home = "/home/austin";
        hashedPassword = "$6$5PZLg16IXRSJaLiI$bU8OB6wng7ZvQcrkpX/x5pjX2GegtYN.YUIAibPvAtVq/nyGwfjLyGwV5GR2LCnEqytFzxxer6.fhAhO7G8lD1";
      };

      jessica = {
        isNormalUser = true;
        extraGroups = [ "networkmanager" ];
        home = "/home/jessica";
        hashedPassword = "$6$CXDT2agbjBSyDEnL$VDtjFbPcD20UWSSOj/h2rrYq/SteAkYBZcQn2N7/8fQpgEJKkxR9MbGokLwUjWvslAcwRDIVUcyOg.0neMFMK1";
      };
    })

    # Darwin-specific user configuration
    (lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
      austin = {
        home = "/Users/austin";
      };

      jessica = {
        home = "/Users/jessica";
      };
    })
  ];
}
