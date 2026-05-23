# users/austin/nixos/desktop-apps.nix
# Shared preferred desktop applications for NixOS Home Manager modules.
{ pkgs
, unstable
, lib
, ...
}:

let
  terminalPackage = unstable.ghostty;
  browserPackage = pkgs.librewolf;
  passwordManagerPackage = pkgs._1password-gui;
  fileManagerPackage = pkgs.xdg-utils;
  networkEditorPackage = pkgs.networkmanagerapplet;
  audioControlPackage = pkgs.pavucontrol;
in
{
  terminal = {
    package = terminalPackage;
    command = "${terminalPackage}/bin/ghostty --working-directory=\"$HOME\"";
  };

  browser = {
    package = browserPackage;
    command = lib.getExe browserPackage;
  };

  passwordManager = {
    package = passwordManagerPackage;
    command = lib.getExe passwordManagerPackage;
  };

  fileManager = {
    package = fileManagerPackage;
    command = "${fileManagerPackage}/bin/xdg-open $HOME";
  };

  networkEditor = {
    package = networkEditorPackage;
    command = "${networkEditorPackage}/bin/nm-connection-editor";
  };

  audioControl = {
    package = audioControlPackage;
    command = "${audioControlPackage}/bin/pavucontrol";
  };
}
