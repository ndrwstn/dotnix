{ ... }:
{
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
      "https://nixvim.cachix.org"
      "https://vicinae.cachix.org"
      "https://ndrwstn-dotnix.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "nixvim.cachix.org-1:5itLbq7pKz5BB8h3QvE93s1zZOSX3XjKBpJZM+Upn7Q="
      "vicinae.cachix.org-1:1kDrfienkGHPYbkpNj1mWTr7Fm1+zcenzgTizIcI3oc="
      "ndrwstn-dotnix.cachix.org-1:FDHQDhPr2ArkrwdCHouf72rOL4ywQsVa0T4i2eG9tGg="
    ];
  };
}
