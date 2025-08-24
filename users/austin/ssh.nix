# SSH configuration for austin user - Data-driven dynamic configuration
{ lib, pkgs, hostName ? "", ... }:
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

  # Note: known_hosts generation moved to programs.ssh.knownHosts

  # Determine authorized keys for this machine
  authorizedKeys =
    if currentMachine != null
    then generateAuthorizedKeys currentMachine
    else lib.mapAttrsToList (name: machineData: machineData.key) sshData.machines; # fallback to machine keys only

  # Note: Setup key deployment is handled at machine level via secrets.nix files
in
{
  # Note: agenix secrets are configured via age.secrets below, not via imports

  programs.ssh = {
    enable = true;

    # Use Nix's built-in known hosts management
    knownHosts = lib.mapAttrs
      (hostname: hostData: {
        hostNames = [ hostname ];
        publicKey = "${hostData.keyType} ${hostData.key}";
      })
      sshData.knownHosts;

    # Configure 1Password SSH agent for all platforms
    extraConfig = ''
      Host *
        IdentityAgent ${
          if pkgs.stdenv.isDarwin 
          then "\"~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock\""
          else "~/.1password/agent.sock"
        }
        SetEnv TERM=xterm-256color
        UpdateHostKeys no
      
      ${generateSSHMatches sshData.sshMatches}
    '';
  };

  # Deploy authorized_keys via home-manager (works on both Darwin and NixOS)
  home.file.".ssh/authorized_keys" = {
    text = lib.concatStringsSep "\n" authorizedKeys;
  };

  # Note: known_hosts is now managed via programs.ssh.knownHosts above

  # Note: SSH setup key is deployed via machine-specific secrets.nix files
  # for machines with setup-key capability (monaco, silver, etc.)
}
