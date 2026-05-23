# secrets/secrets.nix - agenix secrets configuration
let
  # User keys
  austin = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIq17FR5ZqbN7a1uVVwojvvES/f7mgagiixc6OcZicnG austin@impetuo.us";

  # Machine host keys (SSH ed25519 keys)
  monaco = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJSystV+gQ3/tiYxrk/Cmvr0WQBrz6UjA2cVwL8vxtgX";
  silver = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEEasqUb7EN/yKS02tfVNvz8nYzgOhw0DDLz/rTR86Nw";
  plutonium = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGE2j6qGZgIoU2KHQV/1kJSy4nqE2Z11firQ1QlfcWxH plutonium";
  molybdenum = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF5YYde/IMNhabc3FDTMyxoVbGu8Kc/MdBz4DMWunEBx molybdenum";
  siberia = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJYQOiy2ndkowGzWi7Y5uNoEqCum9LV6uCQ/CmNBO/BI siberia";
  svalbard = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHsbGccaMJhs8CjjRaLR+fdDowttD22ecETFsgjhT+if svalbard";

  # Key groups for active machines
  allUsers = [ austin ];
  activeMachines = [ monaco silver plutonium siberia molybdenum svalbard ];

  # Machines with setup-key capability (can receive the universal setup private key)
  setupKeyMachines = [ monaco silver plutonium siberia molybdenum svalbard ];
in
{
  # Individual SSH key files
  "ssh-setup.age".publicKeys = allUsers ++ setupKeyMachines;

  # Syncthing secrets (consolidated)
  "syncthing/config-shared.age".publicKeys = allUsers ++ activeMachines;
  "syncthing/config-monaco.age".publicKeys = allUsers ++ [ monaco ];
  "syncthing/config-silver.age".publicKeys = allUsers ++ [ silver ];
  "syncthing/config-plutonium.age".publicKeys = allUsers ++ [ plutonium ];
  "syncthing/config-siberia.age".publicKeys = allUsers ++ [ siberia ];
  "syncthing/config-molybdenum.age".publicKeys = allUsers ++ [ molybdenum ];
  "syncthing/config-svalbard.age".publicKeys = allUsers ++ [ svalbard ];

  # Atuin shared encryption key (all machines)
  "atuin.age".publicKeys = allUsers ++ activeMachines;

  # Shared general secrets (all machines)
  "general.age".publicKeys = allUsers ++ activeMachines;


  # SSH machine-specific private keys (new pattern)
  "ssh/machine-monaco.age".publicKeys = allUsers ++ [ monaco ];
  "ssh/machine-silver.age".publicKeys = allUsers ++ [ silver ];
  "ssh/machine-plutonium.age".publicKeys = allUsers ++ [ plutonium ];
  "ssh/machine-siberia.age".publicKeys = allUsers ++ [ siberia ];
  "ssh/machine-molybdenum.age".publicKeys = allUsers ++ [ molybdenum ];
  "ssh/machine-svalbard.age".publicKeys = allUsers ++ [ svalbard ];

  # Service SSH keys (new pattern)
  "ssh/key-gitea.age".publicKeys = allUsers ++ activeMachines;
  "ssh/key-github.age".publicKeys = allUsers ++ activeMachines;
}
