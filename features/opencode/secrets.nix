# Secret declaration for the reusable opencode server feature.
# The encrypted payload is intentionally not added to the shared recipient
# policy until a named server is provisioned.
# Its plaintext payload must be shell assignments:
# OPENCODE_SERVER_USERNAME=...
# OPENCODE_SERVER_PASSWORD=...
{ config, lib, pkgs, ... }:

{
  config = lib.mkIf (pkgs.stdenv.isLinux && config.features.opencode.serverSecretFile != null) {
    age.secrets.opencode-server-env = {
      file = config.features.opencode.serverSecretFile;
      owner = "opencode";
      group = "projects";
      mode = "0400";
    };
  };
}
