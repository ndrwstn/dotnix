# Maximum-impermanence policy for disposable virtual machines.
#
# This feature deliberately requires a tmpfs root. The machine still owns the
# durable filesystem layout, but enabling the feature cannot silently turn an
# ordinary persistent root filesystem into a destructive cleanup job.
{ config, inputs, lib, ... }:

let
  cfg = config.features.impermanence;
in
{
  imports = [ inputs.impermanence.nixosModules.impermanence ];

  options.features.impermanence = {
    enable = lib.mkEnableOption "maximum impermanence for a disposable VM";

  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      assertions = [
        {
          assertion = config.fileSystems."/".fsType == "tmpfs";
          message = "maximum impermanence requires a tmpfs root filesystem";
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

      # These are the only mutable paths restored from /persist. /projects is
      # its own durable filesystem and is intentionally not listed here.
      environment.persistence."/persist" = {
        directories = [
          { directory = "/var/lib/nixos"; }
          { directory = "/home/austin/.ssh"; }
          { directory = "/home/austin/.config/opencode"; }
          { directory = "/home/austin/.local/share/opencode"; }
          { directory = "/home/austin/.local/state/opencode"; }
          { directory = "/var/lib/opencode"; }
        ];
        files = [
          { file = "/etc/age/identity.key"; }
          { file = "/etc/ssh/ssh_host_ed25519_key"; }
          { file = "/etc/ssh/ssh_host_ed25519_key.pub"; }
          { file = "/etc/ssh/ssh_host_rsa_key"; }
          { file = "/etc/ssh/ssh_host_rsa_key.pub"; }
          { file = "/etc/ssh/ssh_host_ecdsa_key"; }
          { file = "/etc/ssh/ssh_host_ecdsa_key.pub"; }
        ];
      };

      environment.etc."impermanence-policy.txt".text = ''
        This VM uses a tmpfs root filesystem and starts with a fresh root at boot.
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
      '';
    })
    {

      # Selecting the feature in machine metadata is itself the opt-in.  The
      # filesystem assertions above still require an explicit, safe VM layout.
      features.impermanence.enable = lib.mkDefault true;
    }
  ];
}
