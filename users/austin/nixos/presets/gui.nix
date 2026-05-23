# users/austin/nixos/presets/gui.nix
# Baseline GUI applications for graphical machines.
{ pkgs
, desktopApps
, ...
}:

{
  home.packages = with pkgs; [
    alsa-utils
    blueman
    desktopApps.browser.package
    desktopApps.terminal.package
    neovide
    obsidian
    vlc
    zathura
  ];
}
