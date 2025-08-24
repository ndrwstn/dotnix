# SSH configuration for austin user - Data-driven dynamic configuration
{ lib, pkgs, hostName ? "", config, ... }:
let
  # Import SSH configuration data
  sshData = import ./ssh-data.nix;

  # Helper function to check if a machine has a specific capability
  hasCapability = capability: machine:
    lib.elem capability (machine.capabilities or [ ]);

  # Helper function to get current machine data
  getCurrentMachine = hostName:
    lib.findFirst (machine: machine.hostname == "${lib.toLower hostName}.local") null
      (lib.attrValues sshData.machines);

  # Get current machine configuration
  currentMachine = getCurrentMachine hostName;

  # Generate authorized keys based on machine capabilities
  generateAuthorizedKeys = machine:
    let
      # Always include machine keys (for inter-machine communication)
      machineKeys = lib.mapAttrsToList (name: machineData: machineData.key) sshData.machines;

      # Add device keys if machine has ios-devices capability
      deviceKeys =
        if hasCapability "ios-devices" machine
        then lib.mapAttrsToList (name: deviceData: deviceData.key) sshData.devices
        else [ ];
    in
    machineKeys ++ deviceKeys;

  # Generate SSH client configuration from match rules
  generateSSHMatches = matches:
    lib.concatStringsSep "\n" (map
      (match: ''
        ${match.condition}
          ${lib.concatStringsSep "\n  " (lib.mapAttrsToList (key: value: "${key} ${toString value}") match.config)}
      '')
      matches);

  # Generate known_hosts content
  generateKnownHosts = hosts:
    lib.concatStringsSep "\n" (lib.mapAttrsToList
      (hostname: hostData:
        "${hostname} ${hostData.keyType} ${hostData.key}"
      )
      hosts);

  # Determine authorized keys for this machine
  authorizedKeys =
    if currentMachine != null
    then generateAuthorizedKeys currentMachine
    else lib.mapAttrsToList (name: machineData: machineData.key) sshData.machines; # fallback to machine keys only

  # Check if current machine should receive setup key
  shouldDeploySetupKey = currentMachine != null && hasCapability "setup-key" currentMachine;
in
{
  # Import agenix secrets if this machine has setup-key capability
  imports = lib.optionals shouldDeploySetupKey [
    ../../secrets/secrets.nix
  ];

  programs.ssh = {
    enable = true;

    # Configure 1Password SSH agent for all platforms
    extraConfig = ''
      Host *
        IdentityAgent ${
          if pkgs.stdenv.isDarwin 
          then "\"~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock\""
          else "~/.1password/agent.sock"
        }
      
      ${generateSSHMatches sshData.sshMatches}
    '';
  };

  # Deploy authorized_keys via home-manager (works on both Darwin and NixOS)
  home.file.".ssh/authorized_keys" = {
    text = lib.concatStringsSep "\n" authorizedKeys;
  };

  # Populate known_hosts with machine host keys
  home.file.".ssh/known_hosts" = {
    text = generateKnownHosts sshData.knownHosts;
  };

  # Deploy setup private key via agenix if machine has setup-key capability
  age.secrets = lib.mkIf shouldDeploySetupKey {
    ssh-setup = {
      file = ../../secrets/ssh-setup.age;
      path = "${config.home.homeDirectory}/.ssh/setup";
      mode = "600";
      owner = config.home.username;
    };
  };
}
