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
  _opencode = "age1kcnwc9e79ut35j0lj4g065cvam5q4u6ar02kg7zvxsh8f5806g8sp49xkt";
  naphthalene = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMMk77LSv0SIxasrNcUv+YqDsKX45aE09hThLkoJmz6M";

  # Key groups for active machines
  # NOTE: activeMachines is manually maintained and would benefit from
  # buildMachine automation in the future (auto-collect from machine roles).
  allUsers = [ austin ];
  activeMachines = [ monaco silver plutonium siberia molybdenum svalbard _opencode ];

in
{
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
  "ssh/machine-naphthalene.age".publicKeys = allUsers;

  # Service SSH keys (new pattern)
  "ssh/key-gitea.age".publicKeys = allUsers ++ activeMachines;
  "ssh/key-github.age".publicKeys = allUsers ++ activeMachines;

  # opencode serve password (shared across all clones)
  "opencode-serve-password.age".publicKeys = allUsers ++ activeMachines;

  # _opencode template age identity key (backup — used for VMA builds)
  "templates/opencode.age".publicKeys = allUsers;

  # _opencode template-specific Gitea/GitHub keys (separate from main flake keys)
  # Clones use these so a compromise of a template clone doesn't expose the main keys.
  "ssh/key-gitea-opencode.age".publicKeys = allUsers ++ activeMachines;
  "ssh/key-github-opencode.age".publicKeys = allUsers ++ activeMachines;

  # naphthalene remote builder key — used by activeMachines to SSH into naphthalene
  # for remote builds. The public key is deployed in naphthalene's config.
  "ssh/key-nixbuilder.age".publicKeys = allUsers ++ activeMachines;
}
