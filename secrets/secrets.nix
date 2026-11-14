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
  naphthalene = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCw9FcJ7NSULj4LBgNAOKY1mJz/EontZB3oFPWDBI4ea8ZPR+9t6bC8+z1w+cximOKONDmWtP2ou0BDS6n8FO0YkZbp90n9VpWavvzlgCdY72Hxv/JyJaVDokeDxFXnqSwro8SH8LfovSEI+hVLq+83WaTV609H5HgJqaqoC3Q3Di242bTRwGOZqT2VvcGIwiTVsOl88y89RnGccS5jQc7Ai2/8RenY5MXW0RL6jQCsCOZTFUdlVCYPmUeD7y1feasKOr9D1AwVuqu9Pd9Vzt397uMuOiwH5oSVsuXsvhTJgtiC7TX8tsmJvMOCaioT6aKyBjTjhSYmCQpOlxUd6gbl3MENGAknb12rcG3O20KRVFu44O+vYr2UU/A1S+9r38pmHVbPgevmCw7PPgoXSErAWXgUEr3ySxlAYzb6SvshCYjMh1N6DPCsJgKgsBqTGVs+mRk1iwp7NgW6/9seC3/lU8rbtUMul/1wJscvj43CRb7/erMe/PtPXTtVlj3ctxmDNIhGCUyRLxCMA4z2znVd/7Nnmx5dNGcc3IhDQnGb4edoik7IF9rfLI36uD76HTNDWJZkE7dvK4vZeRbtwDeo8fIQUmn9D3IwAlcAFZWi/uFTfBIXV9LSwFSM/7HWnoItudvxHogD7uOKwtRdAKEjFnHu6kW6hFtOlA9lNF4pdQ== naphthalene";

  # Key groups for active machines
  allUsers = [ austin ];
  activeMachines = [ monaco silver plutonium siberia molybdenum svalbard ];

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

  # Service SSH keys (new pattern)
  "ssh/key-gitea.age".publicKeys = allUsers ++ activeMachines;
  "ssh/key-github.age".publicKeys = allUsers ++ activeMachines;

  # Shared Naphthalene client key. Only the approved clients and Austin may
  # decrypt this credential; Naphthalene itself does not need it.
  "ssh/key-nixbuilder.age".publicKeys = allUsers ++ [ monaco silver siberia ];

  # Shared Cachix upload token for x86_64-linux machines.
  "cachix.age".publicKeys = allUsers ++ [ molybdenum siberia silver naphthalene ];

}
