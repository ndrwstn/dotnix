# users/austin/nixos/default.nix
{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./packages.nix
  ];
}

