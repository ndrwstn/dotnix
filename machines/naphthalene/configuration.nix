# Naphthalene is a small Proxmox LXC used as a Nix remote builder.
{ modulesPath, pkgs, ... }:
{
  imports = [
    (modulesPath + "/virtualisation/proxmox-lxc.nix")
    ./secrets.nix
  ];

  boot.isContainer = true;
  networking.hostName = "Naphthalene";

  services.openssh.enable = true;
  services.openssh.settings = {
    AllowUsers = [ "austin" ];
    PasswordAuthentication = false;
  };

  users.users.austin.openssh.authorizedKeys.keys = [
    # Shared remote-builder client key, provisioned on Monaco, Silver, and
    # Siberia. This is separate from Austin's normal interactive key.
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFPyjU+CecRY5sWljr6NFDCMCrG+WyFMxeVQQRtFiZ5i nixbuilder-client"
  ];

  environment.systemPackages = with pkgs; [ git vim ];

  nix.settings.max-jobs = 4;
  system.stateVersion = "25.05";
}
