# users/austin/nixos/presets/office.nix
# Office application preset.
{ pkgs
, autopkgs
, ...
}:

{
  home.packages = with pkgs; [
    autopkgs.pdfcraft
    autopkgs.deckcraft
    autopkgs.gridcraft
    autopkgs.wordcraft
    autopkgs.craft-fonts
    libreoffice-qt6-fresh
  ];
}
