# secrets/secrets.nix - agenix secrets configuration
let
  # User keys
  austin = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOT2lOzk90kux62qppI55MyN/mjQS8UPrz9H6tCdMJSR austin@impetuo.us";

  # Machine host keys (SSH ed25519 keys)
  monaco = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJSystV+gQ3/tiYxrk/Cmvr0WQBrz6UjA2cVwL8vxtgX";
  silver = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEEasqUb7EN/yKS02tfVNvz8nYzgOhw0DDLz/rTR86Nw";
  # Note: Plutonium and Siberia keys will be added when those machines are activated
  # For now, using placeholder keys that will be updated when machines are deployed
  plutonium = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAYrqn/+SZCfR4TCjIUWCmn1/Os4scpP1fI/pcRtSwnn";
  # siberia = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPlaceholder-key-for-siberia-will-be-updated";

  # Key groups for active machines
  allUsers = [ austin ];
  # activeMachines = [ monaco silver plutonium siberia ];
  activeMachines = [ monaco silver plutonium ];

  # Machines with setup-key capability (can receive the universal setup private key)
  # setupKeyMachines = [ monaco silver plutonium siberia ];
  setupKeyMachines = [ monaco silver plutonium ];
in
{
  # Consolidated secrets with same access control as before
  "wifi-home.age".publicKeys = allUsers ++ activeMachines;

  # Individual SSH key files
  "ssh-setup.age".publicKeys = allUsers ++ setupKeyMachines;

  # Syncthing secrets (consolidated)
  "syncthing.age".publicKeys = allUsers ++ activeMachines; # Shared config for all machines
  "syncthing-monaco.age".publicKeys = allUsers ++ [ monaco ];
  "syncthing-silver.age".publicKeys = allUsers ++ [ silver ];
  "syncthing-plutonium.age".publicKeys = allUsers ++ [ plutonium ];
  # "syncthing-siberia.age".publicKeys = allUsers ++ [ siberia ];

  # Atuin shared encryption key (all machines)
  "atuin.age".publicKeys = allUsers ++ activeMachines;
}
