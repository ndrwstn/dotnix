# users/austin/nixos/presets/gui.nix
# Baseline GUI applications for graphical machines.
{ pkgs
, ...
}:

{
  home.packages = with pkgs; [
    alsa-utils
    blueman
    neovide
    obsidian
    vlc
    zathura
  ];
}
