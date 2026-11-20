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
    # Concurrency budget. Clients reach this builder over the serve protocol
    # (protocol = "ssh" in features/remote-builder), so these values are used
    # as-is; under ssh-ng the client's own cores/max-jobs replace them and
    # neither setting below has any effect on remote builds.
    #
    # Compiler threads are
    #   client maxJobs x max-jobs x cores = 2 x 1 x 3 = 6
    # which is what this 12 GiB container supports for Rust builds at roughly
    # 1.5 GiB per rustc. `max-jobs` only bounds dependency fan-out inside a
    # single build request; fleet concurrency is capped on the clients.
    max-jobs = 1;
    cores = 3;
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

  # Remote builds run inside the SSH login session (the client spawns a fresh
  # nix-store --serve per build), so a memory limit has to live on user.slice.
  # This is a backstop for the budget above, not the budget itself: it turns a
  # build that exceeds it into one failed derivation instead of a
  # container-wide OOM that can take sshd with it. Sized against the 12 GiB
  # container, leaving ~1.5 GiB for system.slice.
  systemd.slices.user.sliceConfig = {
    MemoryHigh = "9G";
    MemoryMax = "10.5G";
  };

  nix.gc = {
    automatic = true;
    dates = "daily";
    options = "--delete-older-than 14d";
  };

  warnings = [ hackFixes.naphthalene.warning ];
  system.stateVersion = "25.05";
}
