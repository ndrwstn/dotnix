{ ... }:
{
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
      "https://nixautopkgs.cachix.org"
      "https://ndrwstn-dotnix.cachix.org"
      "https://vicinae.cachix.org"
      "https://nixvim.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "nixautopkgs.cachix.org-1:dVN391kfq3oI6zACdX380CNiFyHWjXOLQwDNYQWwnbk="
      "ndrwstn-dotnix.cachix.org-1:FDHQDhPr2ArkrwdCHouf72rOL4ywQsVa0T4i2eG9tGg="
      "vicinae.cachix.org-1:1kDrfienkGHPYbkpNj1mWTr7Fm1+zcenzgTizIcI3oc="
      "nixvim.cachix.org-1:8xrm/43sWNaE3sqFYil49+3wO5LqCbS4FHGhMCuPNNA="
      # Retired nixautopkgs key. Still signs cache entries pushed before the
      # rotation to dVN391; drop once those entries have been re-pushed.
      "nixautopkgs.cachix.org-1:TPok4jWKgejIHkNmiRff10yczTIho/Oih57hAdySolUjfhTfraqzXznUq+JNV785WLi+0zkkhOWU4uxz/k3RBg=="
    ];
  };
}
