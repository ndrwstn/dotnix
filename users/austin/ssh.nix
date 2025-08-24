# SSH configuration for austin user
{ lib, pkgs, hostName ? "", ... }:
let
  # All SSH keys managed here
  sshKeys = {
    # Common key for all machines
    nix-remote = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICqZ3Bd80DpUyzZTBul09t9CKRim161zQ2c/uueCS+oZ";

    # Device-specific keys
    bradley = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHoANHywPMoqstT5RNJ/s1rd43C47Iw4gO6RRjLK7FLR";
    halsey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIm56by8poUWuitW20966Mjw+MiVowwtZQR39rbYASm1";
    nimitz = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL5iqDoFpbUH1RmiCGLqfmXzjo1RBZePpZDXaF9bKF1Q";
    mckinley = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOzAvkC7u31iGU33SxdvhytEf+T3uqhxqFsK/9qZ0qt0";
  };

  # Determine which keys to deploy based on hostname
  authorizedKeys =
    if hostName == "Monaco" then
    # Monaco gets all keys
      [ sshKeys.nix-remote sshKeys.bradley sshKeys.halsey sshKeys.nimitz sshKeys.mckinley ]
    else
    # All other machines get just nix-remote
      [ sshKeys.nix-remote ];
in
{
  programs.ssh = {
    enable = true;

    # Configure 1Password SSH agent for all platforms
    extraConfig = ''
      Host *
        IdentityAgent ${
          if pkgs.stdenv.isDarwin 
          then "\"~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock\""
          else "~/.1password/agent.sock"
        }
    '';
  };

  # Deploy authorized_keys via home-manager (works on both Darwin and NixOS)
  home.file.".ssh/authorized_keys" = {
    text = lib.concatStringsSep "\n" authorizedKeys;
  };

  # Populate known_hosts with machine host keys
  home.file.".ssh/known_hosts" = {
    text = ''
      monaco.local ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJSystV+gQ3/tiYxrk/Cmvr0WQBrz6UjA2cVwL8vxtgX
      silver.local ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEEasqUb7EN/yKS02tfVNvz8nYzgOhw0DDLz/rTR86Nw
    '';
  };
}
