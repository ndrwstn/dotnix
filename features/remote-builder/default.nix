# Nix client configuration for the shared Naphthalene builder.
#
# Builder access is bootstrapped manually.  In particular, the local host key
# is an agenix decryption identity, not an SSH client credential.  Operators
# must provide a dedicated client key through this option when enabling the
# feature; leaving it unset keeps evaluation valid without claiming that an
# agenix-managed key exists.
{ config, lib, ... }:
let
  cfg = config.features.remote-builder;
in
{
  options.features.remote-builder.sshKey = lib.mkOption {
    type = lib.types.nullOr lib.types.str;
    default = null;
    description = "Manually provisioned SSH private key used for the remote builder.";
  };

  config = {
    warnings = lib.optional (cfg.sshKey == null)
      "remote-builder is selected but no client SSH key is configured; bootstrap it manually before enabling distributed builds.";
    nix.distributedBuilds = cfg.sshKey != null;
    nix.buildMachines = lib.optional (cfg.sshKey != null) ({
      system = "x86_64-linux";
      sshUser = "austin";
      protocol = "ssh-ng";
      maxJobs = 4;
      supportedFeatures = [ ];
      hostName = "naphthalene.impetuo.us";
      sshKey = cfg.sshKey;
    });
  };
}
