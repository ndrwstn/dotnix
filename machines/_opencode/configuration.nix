{ config, pkgs, lib, modulesPath, inputs, unstable, autopkgs, ... }:

let
  inherit (lib) mkDefault mkForce;
in
{
  imports = [
    # QEMU guest profile for Proxmox VMs
    (modulesPath + "/profiles/qemu-guest.nix")
    # Proxmox image module (for VMA build + cloud-init)
    (modulesPath + "/virtualisation/proxmox-image.nix")
    # Impermanence module
    inputs.impermanence.nixosModules.impermanence
    # Machine-specific secrets
    ./secrets.nix
  ];

  # ============================================================================
  # Machine metadata
  # ============================================================================
  _astn.machineSystem = "x86_64-linux";
  _astn.machineRole = "template";

  # ============================================================================
  # Proxmox VM Image Configuration
  # ============================================================================
  # These settings configure the VMA image for Proxmox.
  # Build with: nixos-rebuild build-image --image-variant proxmox --flake .#_opencode

  proxmox.qemuConf = {
    cores = 2;
    memory = 2048; # 2 GB minimum (ballooned to 4 GB via qemuExtraConf)
    net0 = "virtio,bridge=vmbr0,tag=50";
  };

  # Ballooning configuration — 2 GB min / 4 GB max
  proxmox.qemuExtraConf = {
    balloon = 1;
    args = "-device virtio-balloon-pci,id=balloon0";
  };

  virtualisation.diskSize = 51200; # 50 GB (thin-provisioned, expandable)

  # ============================================================================
  # Disk image builder memory
  # ============================================================================
  # The cloudImage builder spawns a QEMU VM to assemble the raw disk.
  # Default VM RAM is 1024 MB, which OOMs with larger system closures.
  # Override with 2048 MB to provide breathing room during image assembly.
  # Uses pkgs.lib (nixpkgs lib matching the make-disk-image.nix source)
  # rather than config.lib to avoid lib version mismatches.
  system.build.cloudImage = lib.mkForce (
    import "${toString pkgs.path}/nixos/lib/make-disk-image.nix" {
      lib = pkgs.lib;
      inherit pkgs config;
      name = config.image.baseName;
      baseName = config.image.baseName;
      partitionTableType = config.proxmox.partitionTableType;
      additionalSpace = config.proxmox.qemuConf.additionalSpace;
      bootSize = config.proxmox.qemuConf.bootSize;
      diskSize = config.virtualisation.diskSize;
      format = "raw";
      memSize = 2048;
    }
  );

  # ============================================================================
  # Cloud-init (for per-clone hostname)
  # ============================================================================
  # The proxmox-image module enables cloud-init by default.
  # Proxmox sets hostname per clone via cloud-init; this is a fallback.
  networking.hostName = mkDefault "opencode";

  # ============================================================================
  # Networking
  # ============================================================================
  # VLAN 50 is configured in proxmox.qemuConf.net0 above.
  # Cloud-init handles network config via systemd-networkd.
  networking.useDHCP = mkDefault true;

  # ============================================================================
  # Nix settings
  # ============================================================================
  nixpkgs.config.allowUnfree = true;

  # nix-ld for dynamically linked binaries (opencode is Bun-compiled)
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    # Core runtime libraries
    zlib
    zstd
    stdenv.cc.cc
    curl
    openssl
    attr
    libssh
    bzip2
    libxml2
    acl
    libsodium
    util-linux
    xz
    systemd
    # Bun-specific libraries
    brotli
    libffi
    gmp
  ];

  # ============================================================================
  # Users
  # ============================================================================
  users.users = {
    # System user for running opencode serve
    opencode = {
      isSystemUser = true;
      description = "Opencode service user";
      home = "/var/lib/opencode";
      createHome = true;
      group = "projects";
      shell = "${pkgs.shadow}/bin/nologin"; # No interactive login
    };

    # Personal user for SSH access (lazygit, tmux, shell)
    # Note: description (Andrew Austin) and basic config come from
    # systems/common/users.nix — only VM-specific overrides here
    austin = {
      extraGroups = [ "projects" "wheel" ];
      openssh.authorizedKeys.keys = [
        # Primary key deployed via agenix; this is a bootstrap/fallback
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIq17FR5ZqbN7a1uVVwojvvES/f7mgagiixc6OcZicnG austin@impetuo.us"
      ];
    };
  };

  # Shared group for project file access
  users.groups.projects = { };

  # ============================================================================
  # SSH Server
  # ============================================================================
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
    # Don't generate SSH host keys in the template —
    # each clone generates unique keys on first boot, persisted via impermanence
    startWhenNeeded = false;
  };

  # ============================================================================
  # opencode Serve — Systemd Service
  # ============================================================================
  systemd.services.opencode-serve = {
    description = "Opencode AI Coding Agent Server";
    after = [ "cloud-init.service" "network.target" "agenix.service" ];
    wants = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "simple";
      User = "opencode";
      WorkingDirectory = "/var/lib/opencode";
      ExecStart = "${autopkgs.opencode}/bin/opencode serve --hostname 0.0.0.0 --port 4096";
      Restart = "on-failure";
      RestartSec = 5;
      # Daily restart to clear server-side memory leaks (known issue in v1.x)
      RuntimeMaxSec = 86400;
      # Environment
      EnvironmentFile = "/run/agenix/opencode-serve-env";
    };
  };

  # ============================================================================
  # Persistent State Management
  # ============================================================================
  # Safety model: NixOS is inherently immutable — the system configuration
  # lives in /nix/store and is regenerated on every activation. If the agent
  # modifies system files (/etc, /var, etc.), a reboot + nixos-rebuild restores
  # them from the config. The only things that persist across reboots are:
  #
  #   - /nix/store (immutable package store)
  #   - /home/austin (SSH keys, opencode config, atuin history)
  #   - /var/lib/opencode (opencode session data)
  #
  # The impermanence module explicitly defines what's PERSISTENT.
  # Everything else resets because NixOS config always wins on boot.
  # For a fully clean slate, re-clone from the Proxmox template.

  # Set up persistent data directories
  systemd.tmpfiles.rules = [
    "d /persist/etc/age 0750 root root -"
    "d /persist/etc/ssh 0755 root root -"
    "d /persist/var/log 0755 root root -"
    "d /persist/home/austin/.ssh 0700 austin projects -"
    "d /persist/home/austin/.local/share/opencode 0755 austin projects -"
    "d /persist/var/lib/opencode/.local/share/opencode 0755 opencode projects -"
    "d /persist/var/lib/nixos 0755 root root -"
    "d /projects 2770 austin projects -"
  ];

  # Use the impermanence module to bind-mount persistent paths
  # NOTE: /etc/ssh is NOT persisted as a directory — that would bind-mount
  # /persist/etc/ssh over /etc/ssh, hiding sshd_config (generated by NixOS
  # activation). Instead, individual SSH host key files are persisted.
  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      # NixOS UID/GID database (prevents UID reassignment on reboot)
      "/var/lib/nixos"
      "/var/log"
      "/home/austin/.ssh"
      "/home/austin/.local/share/opencode"
      "/var/lib/opencode/.local/share/opencode"
    ];
    files = [
      "/etc/age/identity.key"
      # SSH host keys (generated by first-boot-setup, persisted individually
      # so the impermanence bind-mount doesn't hide NixOS-generated configs)
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_ed25519_key.pub"
      "/etc/ssh/ssh_host_rsa_key"
      "/etc/ssh/ssh_host_rsa_key.pub"
      "/etc/ssh/ssh_host_ecdsa_key"
      "/etc/ssh/ssh_host_ecdsa_key.pub"
    ];
  };

  # /projects is a directory on root (persists naturally on ext4)

  # First-boot setup: persist the age identity key and create SSH host keys
  systemd.services.first-boot-setup = {
    description = "First-boot setup for persisting identity keys";
    before = [ "agenix.service" "sshd.service" ];
    wantedBy = [ "agenix.service" ];
    after = [ "cloud-init.service" "local-fs.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      # Persist age identity key (for agenix decryption across reboots)
      if [ ! -f /persist/etc/age/identity.key ] && [ -f /etc/age/identity.key ]; then
        mkdir -p /persist/etc/age
        cp /etc/age/identity.key /persist/etc/age/identity.key
      fi

      # Generate SSH host keys if they don't exist (unique per clone)
      if [ ! -f /persist/etc/ssh/ssh_host_ed25519_key ]; then
        ssh-keygen -t ed25519 -f /persist/etc/ssh/ssh_host_ed25519_key -N "" -C "root@$(hostname)"
        ssh-keygen -t rsa -b 4096 -f /persist/etc/ssh/ssh_host_rsa_key -N "" -C "root@$(hostname)"
        ssh-keygen -t ecdsa -f /persist/etc/ssh/ssh_host_ecdsa_key -N "" -C "root@$(hostname)"
      fi
    '';
  };

  # ============================================================================
  # First-boot identity contract
  # ============================================================================
  # Writes /etc/clone-identity.jsonc on first boot. This file captures the
  # clone's unique identity (hostname, SSH host key, age key) so the operator
  # can extract it, fill in setup.projects, and optionally register the clone
  # in the flake via bin/new-opencode-clone.
  #
  # The file regenerates every boot (/etc is ephemeral), but the identity is
  # stable (SSH keys persisted, hostname from cloud-init always the same).
  systemd.services.clone-identity = {
    description = "Generate clone identity contract";
    after = [ "cloud-init.service" "first-boot-setup.service" ];
    wants = [ "cloud-init.service" "first-boot-setup.service" ];
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.age ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
            HOSTNAME=$(hostname -s)
            FQDN="$${HOSTNAME}.impetuo.us"
            SSH_KEY=$(cat /etc/ssh/ssh_host_ed25519_key.pub 2>/dev/null || echo "unavailable")
            AGE_PUB=$(age-keygen -y /etc/age/identity.key 2>/dev/null || echo "unavailable")
            NOW=$(date -u +%Y-%m-%dT%H:%M:%SZ)

            cat > /etc/clone-identity.jsonc << 'IDENTITY'
      {
        "$schema": "opencode-clone-identity",
        "schema_version": 1,
        "template": "_opencode",
        "hostname": "'"$HOSTNAME"'",
        "fqdn": "'"$FQDN"'",
        "role": "virtual",
        "created": "'"$NOW"'",
        "identities": {
          "ssh_host_ed25519_pub": "'"$SSH_KEY"'",
          "age_pub": "'"$AGE_PUB"'",
          "secrets_recipient_entry": "'"$HOSTNAME"' = \"'"$(echo "$SSH_KEY" | cut -d' ' -f1-2)"'\";"
        },
        "setup": {
          "projects": []
        }
      }
      IDENTITY
    '';
  };

  # ============================================================================
  # Repo provisioning
  # ============================================================================
  # Reads setup.projects from /etc/clone-identity.jsonc and clones each repo
  # into /projects/<name>/. Runs on every boot — skips repos that already exist.
  # Designed for the first nixos-rebuild --target-host deploy.
  systemd.services.clone-provision = {
    description = "Clone configured projects from identity contract";
    after = [ "cloud-init.service" "network-online.target" ];
    wants = [ "cloud-init.service" "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.jq ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      IDENTITY_FILE="/etc/clone-identity.jsonc"

      if [ ! -f "$IDENTITY_FILE" ]; then
        exit 0
      fi

      # Parse projects from the JSONC (strip comments first)
      PROJECTS=$(sed 's|//.*||g' "$IDENTITY_FILE" | ${pkgs.jq}/bin/jq -c '.setup.projects[]? // empty' 2>/dev/null || true)

      if [ -z "$PROJECTS" ]; then
        echo "No projects configured in $IDENTITY_FILE — skipping clone-provision."
        exit 0
      fi

      echo "$PROJECTS" | while IFS= read -r project; do
        NAME=$(echo "$project" | ${pkgs.jq}/bin/jq -r '.name // (.repository | split("/") | last)')
        HOST=$(echo "$project" | ${pkgs.jq}/bin/jq -r '.host // "github.com"')
        REPO=$(echo "$project" | ${pkgs.jq}/bin/jq -r '.repository')
        KEY=$(echo "$project" | ${pkgs.jq}/bin/jq -r '.key // ""')
        BRANCH=$(echo "$project" | ${pkgs.jq}/bin/jq -r '.branch // ""')

        TARGET="/projects/$NAME"

        if [ -d "$TARGET/.git" ]; then
          echo "Already cloned: $REPO → $TARGET"
          continue
        fi

        mkdir -p "$TARGET"

        KEY_FLAG=""
        [ -n "$KEY" ] && KEY_FLAG="-i $${HOME}/.ssh/$${KEY}"

        BRANCH_FLAG=""
        [ -n "$BRANCH" ] && BRANCH_FLAG="-b $${BRANCH}"

        GIT_SSH_COMMAND="ssh $KEY_FLAG" \
          git clone $BRANCH_FLAG "git@$${HOST}:$${REPO}.git" "$TARGET" || \
          echo "Warning: failed to clone $REPO — check SSH key access"
      done
    '';
  };

  # ============================================================================
  # Firewall
  # ============================================================================
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      22 # SSH
      4096 # opencode serve
    ];
  };

  # ============================================================================
  # System settings
  # ============================================================================
  system.stateVersion = "26.05";
  time.timeZone = "America/New_York";
  i18n.defaultLocale = "en_US.UTF-8";

  # ============================================================================
  # Environment packages
  # ============================================================================
  environment.systemPackages = with pkgs; [
    # Core CLI tools
    git
    vim
    lazygit
    ripgrep
    fd
    htop
    jq
    tree
    unzip
  ];

  # ============================================================================
  # Home-manager — CLI-only user configuration
  # ============================================================================
  # Override the auto-discovered home-manager config with a CLI-only subset
  # that excludes desktop-oriented programs (ghostty, syncthing, etc.)
  home-manager.users.austin = lib.mkForce {
    imports = [
      ../../users/austin/tmux.nix
      ../../users/austin/git.nix
      ../../users/austin/atuin.nix
      # Note: ssh.nix is not imported — it contains machine-specific orchestration
      # that assumes known machine names. The VM uses a minimal SSH config instead.
      # Note: nixvim is not imported here — it's set via programs.nixvim below
    ];

    # Essential home-manager identity options
    home = {
      username = "austin";
      homeDirectory = "/home/austin";
      stateVersion = "24.05";
    };

    # Enable XDG base directory support
    xdg.enable = true;

    programs = {
      # Enable shell
      zsh.enable = true;

      # SSH — minimal config for Gitea/GitHub access via agenix-deployed keys
      ssh = {
        enable = true;
        enableDefaultConfig = false;
        extraOptionOverrides = {
          IdentitiesOnly = "yes";
          StrictHostKeyChecking = "accept-new";
        };
        settings = {
          "gitea.impetuo.us" = {
            HostName = "gitea.impetuo.us";
            User = "git";
            IdentityFile = "~/.ssh/id_gitea";
            ForwardAgent = true;
          };
          "github.com" = {
            HostName = "github.com";
            User = "git";
            IdentityFile = "~/.ssh/id_github";
            ForwardAgent = true;
          };
        };
      };

      # Neovim configuration — imported as a value, not a module import
      nixvim = import ../../users/austin/nixvim {
        inherit config pkgs lib;
        texlivePackage = import ../../users/austin/texlive.nix { inherit pkgs; };
        inherit unstable;
      };
    };

    # Disable programs that depend on a desktop environment
    programs.ghostty.enable = lib.mkForce false;
  };

  # ============================================================================
  # Aynchronous cleanup
  # ============================================================================
  # Weekly SQLite VACUUM to keep the opencode session database lean
  systemd.timers.opencode-db-vacuum = {
    description = "Weekly opencode SQLite VACUUM";
    timerConfig = {
      OnCalendar = "weekly";
      Persistent = true;
    };
    wantedBy = [ "timers.target" ];
  };

  systemd.services.opencode-db-vacuum = {
    description = "Vacuum opencode SQLite database";
    serviceConfig = {
      Type = "oneshot";
      User = "opencode";
      ExecStart = "${pkgs.sqlite}/bin/sqlite3 /var/lib/opencode/.local/share/opencode/opencode.db \"VACUUM;\"";
    };
  };
}
