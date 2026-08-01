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

  # Client authorized keys are provisioned manually during builder bootstrap.

  environment.systemPackages = with pkgs; [ git vim ];

  nix.settings.max-jobs = 4;
  system.stateVersion = "25.05";
}
