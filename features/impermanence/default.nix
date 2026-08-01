# Maximum-impermanence policy for future, explicitly provisioned opencode VMs.
#
# This deliberately does not guess a disk layout or root filesystem format.
# A machine must provide the three durable mounts and an initrd command that
# resets its ephemeral root.  This keeps the feature reusable without silently
# destroying an existing machine's root filesystem.
{ config, inputs, lib, ... }:

let
  cfg = config.features.impermanence;
in
{
  imports = [ inputs.impermanence.nixosModules.impermanence ];

  options.features.impermanence = {
    enable = lib.mkEnableOption "maximum impermanence for a disposable VM";

    rootResetCommand = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = ''
        Explicit initrd command which resets the VM's ephemeral root while
        preserving the separately mounted /nix, /persist, and /projects.
        This is required because the safe command depends on the filesystem.
      '';
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      assertions = [
        {
          assertion = cfg.rootResetCommand != "";
          message = "features.impermanence.rootResetCommand must be set for the VM filesystem layout";
        }
        {
          assertion = lib.hasAttr "/nix" config.fileSystems;
          message = "impermanence requires an explicit durable /nix filesystem";
        }
        {
          assertion = lib.hasAttr "/persist" config.fileSystems;
          message = "impermanence requires an explicit durable /persist filesystem";
        }
        {
          assertion = lib.hasAttr "/projects" config.fileSystems;
          message = "impermanence requires an explicit durable /projects filesystem";
        }
      ];

      boot.initrd.postDeviceCommands = lib.mkAfter cfg.rootResetCommand;

      # These are the only paths the reset command is expected to restore from
      # /persist.  The command is machine-specific; no generic symlink or mount
      # operation is performed here.
      environment.persistence."/persist" = {
        hideMounts = true;
        directories = [
          "/var/lib/nixos"
          "/home/austin/.ssh"
          "/home/austin/.config/opencode"
          "/home/austin/.local/share/opencode"
          "/var/lib/opencode"
        ];
        files = [
          "/etc/age/identity.key"
          "/etc/ssh/ssh_host_ed25519_key"
          "/etc/ssh/ssh_host_ed25519_key.pub"
          "/etc/ssh/ssh_host_rsa_key"
          "/etc/ssh/ssh_host_rsa_key.pub"
          "/etc/ssh/ssh_host_ecdsa_key"
          "/etc/ssh/ssh_host_ecdsa_key.pub"
        ];
      };

      environment.etc."impermanence-policy.txt".text = ''
        This VM resets its root filesystem at boot.
        Durable mounts: /nix, /persist, /projects.
        Preserve only:
          /etc/ssh/ssh_host_*_key
          /etc/age/identity.key
          /var/lib/nixos
          /home/austin/.ssh
          /home/austin/.local/share/opencode
          /home/austin/.config/opencode
          /var/lib/opencode
          /projects
        The machine's rootResetCommand must implement these filesystem-specific
        preservation steps; this feature intentionally makes no disk-layout
        assumptions.
      '';
    })
    {

      # Selecting the feature in machine metadata is itself the opt-in.  The
      # filesystem assertions above still require an explicit, safe VM layout.
      features.impermanence.enable = lib.mkDefault true;
    }
  ];
}
