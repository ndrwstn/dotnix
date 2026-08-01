{ pkgs, ... }:
{
  nixpkgs.config.allowBroken = true;
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [ vim wget zsh sops age ];
}
