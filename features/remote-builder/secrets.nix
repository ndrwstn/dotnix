{ pkgs, ... }:
{
  age.secrets.nixbuilder-client = {
    file = ../../secrets/ssh/key-nixbuilder.age;
    mode = "0400";
    owner = "root";
    group = if pkgs.stdenv.isDarwin then "wheel" else "root";
  };

  features.remote-builder.sshKey = "/run/agenix/nixbuilder-client";
}
