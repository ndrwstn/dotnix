# systems/nixos/default.nix
# NixOS platform plumbing shared by all NixOS roles.
{ ... }:
{
  imports = [
    ./agenix.nix
  ];
}
