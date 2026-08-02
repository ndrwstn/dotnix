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
      supportedFeatures = [ ];
      mandatoryFeatures = [ ];
      hostName = "naphthalene.impetuo.us";
      # Nix expects base64 of the complete OpenSSH public-key file.
      publicHostKey = "c3NoLXJzYSBBQUFBQjNOemFDMXljMkVBQUFBREFRQUJBQUFDQVFDdzlGY0o3TlNVTGo0TEJnTkFPS1kxbUp6L0VvbnRaQjNvRlBXREJJNGVhOFpQUis5dDZiQzgrejF3K2N4aW1PS09ORG1XdFAyb3UwQkRTNm44Rk8wWWtaYnA5MG45VnBXYXZ2emxnQ2RZNzJIeHYvSnlKYVZEb2tlRHhGWG5xU3dybzhTSDhMZm92U0VJK2hWTHErODNXYVRWNjA5SDVIZ0pxYXFvQzNRM0RpMjQyYlRSd0dPWnFUMlZ2Y0dJd2lUVnNPbDg4eTg5Um5HY2NTNWpRYzdBaTIvOFJlblk1TVhXMFJMNmpRQ3NDT1pURlVkbFZDWVBtVWVEN3kxZmVhc0tPcjlEMUF3VnVxdTlQZDlWenQzOTd1TXVPaXdINW9TVnN1WHN2aFRKZ3RpQzdUWDh0c21Kdk1PQ2Fpb1Q2YUt5QmpUamhTWW1DUXBPbHhVZDZnYmwzTUVOR0FrbmIxMnJjRzNPMjBLUlZGdTQ0Tyt2WXIyVVUvQTFTKzlyMzhwbUhWYlBnZXZtQ3c3UFBnb1hTRXJBV1hnVUVyM3lTeGxBWXpiNlN2c2hDWWpNaDFONkRQQ3NKZ0tnc0JxVEdWcyttUmsxaXdwN05nVzYvOXNlQzMvbFU4cmJ0VU11bC8xd0pzY3ZqNDNDUmI3L2VyTWUvUHRQWFR0VmxqM2N0eG1ETkloR0NVeVJMeENNQTR6MnpuVmQvN05ubXg1ZE5HY2MzSWhEUW5HYjRlZG9pazdJRjlyZkxJMzZ1RDc2SFRORFdKWmtFN2R2SzR2WmVSYnR3RGVvOGZJUVVtbjlEM0l3QWxjQUZaV2kvdUZUZkJJWFY5TFN3RlNNLzdIV25vSXR1ZHZ4SG9nRDd1T0t3dFJkQUtFakZuSHU2a1c2aEZ0T2xBOWxORjRwZFE9PQo=";
      sshKey = cfg.sshKey;
    });
  };
}
