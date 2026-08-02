{ ... }:
{
  age.secrets.nixbuilder-client = {
    file = ../../secrets/ssh/key-nixbuilder.age;
    path = "/run/agenix/nixbuilder-client";
    mode = "0400";
    owner = "root";
    group = "root";
  };

  features.remote-builder.sshKey = "/run/agenix/nixbuilder-client";
}
