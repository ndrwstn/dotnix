# systems/common/users.nix
# Common user configurations
{
  config,
  pkgs,
  lib,
  ...
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
        extraGroups = ["networkmanager" "wheel" "disk" "plugdev"];
        home = "/home/austin";
      };
      
      jessica = {
        isNormalUser = true;
        extraGroups = ["networkmanager"];
        home = "/home/jessica";
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
