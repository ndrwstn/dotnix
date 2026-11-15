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
    environment.etc."ssh/ssh_config.d/90-nix-remote-builder.conf".text = ''
      Host naphthalene.impetuo.us
        IdentitiesOnly yes
        IdentityAgent none
    '';
    nix.buildMachines = lib.optional (cfg.sshKey != null) ({
      system = "x86_64-linux";
      sshUser = "austin";
      protocol = "ssh-ng";
      maxJobs = 4;
      speedFactor = 1;
      supportedFeatures = [ "kvm" ];
      mandatoryFeatures = [ ];
      hostName = "naphthalene.impetuo.us";
      # Nix expects base64 of the complete OpenSSH public-key file.
      publicHostKey = "c3NoLXJzYSBBQUFBQjNOemFDMXljMkVBQUFBREFRQUJBQUFDQVFDbUd0dlBaYUZEZll3ZndOQ010OGNEMVBFOXA5RWYzV3FpZlh6d3hHVmNud2FIUjd3b2FJL1BqOGRSeTdZMlpBdkphZERrSUw5cnpmNThLd3N2UU11UnZ6T3JTK1BGd2xKbFNDdDF3MmJEWWdEV2VzczBoTzdJSVE4MDgxMlFlYkYzS2crK1FVamFHRXJ3bnhhWXB1bDMva2ZHSVlCdGtpL3YySUpDVUhhc3NYOE9nNXBkbGo4UkpQNVNWZnNsRWlkRWNEMEsvTXAvNzBJY05weW9IdjJXNEsrcTJlcmUvZVVqT0hORDZNbStoYXdOay9VU3BPUHBZZGt4amdPejdyM0F4Q0NSUHRSWXNhYldXMkhMaElQUll2bHF5dmJWamRJQXEzUmF3SWc2SVpUdVVGL2J1N0Qxb3ZjTkZoMnNaQ2ZRODJVN3kvVytCdFYyZnNyelBIbzdUOE85cTVMcHliK2JZU0tLRVptanA5VzN4K1hIdE9sd3VuYlhiYWpNQlhldkxOUXpDb3BZRHJMVDA1Qm5tam1UOE5Xd2d4YXBvZUN2T2I2K2NuQkFyZ2kwTGFXRTlnMFZLT2puTVZsL0FtZUtFY0hLOEc0MThuT0RsWWRRQ2FDUkdIbll3Uzk4WUVOVzBKUzJtZlJvSkV0VjBNUkFQRXJ3UnZTSGFrM1lRaVQxWjl6UGZCdENxSjhKZnJNWFY2ZjhaVnRMZjdiSy9tKzFJRjNKMUdxRHQxTjZrd1l6dmNyWkZ2TEwzdHY2QnREVHZXY3FSMmtCaUpsRHFXM1gxK0wzWkxNa2dyVm00K1lRTXdSeUJiYm0zdWZkemFHZUYyMjBSODFialBZR2hoZ2YvTEh1M1VnUTdGeUhhZjJKaWtEcjJnb3hPVG1MdkJNL3NqKytkaW9sS3c9PQo=";
      sshKey = cfg.sshKey;
    });
  };
}
