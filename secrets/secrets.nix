# secrets/secrets.nix - agenix secrets configuration
let
  # User keys
  austin = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOT2lOzk90kux62qppI55MyN/mjQS8UPrz9H6tCdMJSR austin@impetuo.us";

  # Machine host keys (SSH ed25519 keys)
  monaco = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJSystV+gQ3/tiYxrk/Cmvr0WQBrz6UjA2cVwL8vxtgX";
  silver = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEEasqUb7EN/yKS02tfVNvz8nYzgOhw0DDLz/rTR86Nw";
  # Note: Plutonium and Siberia keys will be added when those machines are activated

  # Key groups for active machines
  allUsers = [ austin ];
  activeMachines = [ monaco silver ];

  # Machines with setup-key capability (can receive the universal setup private key)
  setupKeyMachines = [ monaco silver ]; # plutonium and molybdenum will be added when activated
in
{
  # WiFi secrets - accessible by all active machines and users
  "wifi-home-ssid.age".publicKeys = allUsers ++ activeMachines;
  "wifi-home-psk.age".publicKeys = allUsers ++ activeMachines;

  # SSH setup key - deployed only to machines with setup-key capability
  "ssh-setup.age".publicKeys = allUsers ++ setupKeyMachines;

  # Syncthing secrets - per active machine
  "syncthing-monaco-device-id.age".publicKeys = allUsers ++ [ monaco ];
  "syncthing-monaco-cert.age".publicKeys = allUsers ++ [ monaco ];
  "syncthing-monaco-key.age".publicKeys = allUsers ++ [ monaco ];

  "syncthing-silver-device-id.age".publicKeys = allUsers ++ [ silver ];
  "syncthing-silver-cert.age".publicKeys = allUsers ++ [ silver ];
  "syncthing-silver-key.age".publicKeys = allUsers ++ [ silver ];
}
