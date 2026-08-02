# Nix client configuration for the shared Naphthalene builder.
#
# Builder access is bootstrapped manually. In particular, the local host key
# is an agenix decryption identity, not an SSH client credential. The selected
# feature secret supplies the shared client key after its recipients and
# ciphertext have been provisioned.
{ config, lib, ... }:
let
  cfg = config.features.remote-builder;
in
{
  imports = [ ./secrets.nix ];

  options.features.remote-builder.sshKey = lib.mkOption {
    type = lib.types.nullOr lib.types.str;
    default = null;
    description = "Manually provisioned SSH private key used for the remote builder.";
  };

  config = {
    nix.distributedBuilds = cfg.sshKey != null;
    nix.settings.builders-use-substitutes = true;
    nix.buildMachines = lib.optional (cfg.sshKey != null) ({
      system = "x86_64-linux";
      sshUser = "austin";
      protocol = "ssh-ng";
      maxJobs = 4;
      speedFactor = 1;
      supportedFeatures = [ ];
      mandatoryFeatures = [ ];
      hostName = "naphthalene.impetuo.us";
      publicHostKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCw9FcJ7NSULj4LBgNAOKY1mJz/EontZB3oFPWDBI4ea8ZPR+9t6bC8+z1w+cximOKONDmWtP2ou0BDS6n8FO0YkZbp90n9VpWavvzlgCdY72Hxv/JyJaVDokeDxFXnqSwro8SH8LfovSEI+hVLq+83WaTV609H5HgJqaqoC3Q3Di242bTRwGOZqT2VvcGIwiTVsOl88y89RnGccS5jQc7Ai2/8RenY5MXW0RL6jQCsCOZTFUdlVCYPmUeD7y1feasKOr9D1AwVuqu9Pd9Vzt397uMuOiwH5oSVsuXsvhTJgtiC7TX8tsmJvMOCaioT6aKyBjTjhSYmCQpOlxUd6gbl3MENGAknb12rcG3O20KRVFu44O+vYr2UU/A1S+9r38pmHVbPgevmCw7PPgoXSErAWXgUEr3ySxlAYzb6SvshCYjMh1N6DPCsJgKgsBqTGVs+mRk1iwp7NgW6/9seC3/lU8rbtUMul/1wJscvj43CRb7/erMe/PtPXTtVlj3ctxmDNIhGCUyRLxCMA4z2znVd/7Nnmx5dNGcc3IhDQnGb4edoik7IF9rfLI36uD76HTNDWJZkE7dvK4vZeRbtwDeo8fIQUmn9D3IwAlcAFZWi/uFTfBIXV9LSwFSM/7HWnoItudvxHogD7uOKwtRdAKEjFnHu6kW6hFtOlA9lNF4pdQ==";
      sshKey = cfg.sshKey;
    });
  };
}
