# Naphthalene is a small Proxmox LXC used as a Nix remote builder.
{ modulesPath, pkgs, hackFixes, ... }:
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

  nix.settings = {
    max-jobs = 4;
    cores = 4;
    # Avoid SQLite WAL's db.sqlite-shm fsync path on the ZFS-backed LXC.
    use-sqlite-wal = false;
    # Start store maintenance before the filesystem is exhausted.
    min-free = 5 * 1024 * 1024 * 1024;
    max-free = 10 * 1024 * 1024 * 1024;
    auto-optimise-store = true;
    system-features = [ "kvm" ];
    # The remote-build client uploads locally-built dependencies over SSH. The
    # builder must trust its SSH user to accept those unsigned store paths.
    trusted-users = [ "austin" ];
  };

  nix.gc = {
    automatic = true;
    dates = "daily";
    options = "--delete-older-than 14d";
  };

  warnings = [ hackFixes.naphthalene.warning ];
  system.stateVersion = "25.05";
}
