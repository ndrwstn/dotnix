# users/austin/secrets.nix
{ ... }:

{
  # SSH configuration
  programs.ssh = {
    enable = true;
    matchBlocks = {
      # Add SSH host configurations here when needed
    };
  };
}
