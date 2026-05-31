# machines/siberia/configuration.nix
{ config
, lib
, pkgs
, unstable
, ...
}: {
  imports = [
    ./secrets.nix
  ];
  # Machine metadata (used by flake.nix, does not affect system configuration)
  _astn.machineSystem = "x86_64-linux";
  _astn.machine.windowManagers = [ "hyprland" ];
  _astn.presets = {
    graphics.enable = false;
    maker.enable = false;
    recording.enable = false;
    office.enable = false;
    radio.enable = false;
  };

  # Enable Bluetooth support
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  # nqptp — precision timing daemon required by AirPlay 2 (shairport-sync).
  # Runs as a system service (system user 'nqptp') since it only needs network
  # access and has no dependency on the desktop session.
  users.users.nqptp = {
    isSystemUser = true;
    group = "nqptp";
    description = "NQPTP daemon user";
  };
  users.groups.nqptp = { };

  systemd.services.nqptp = {
    description = "NQPTP -- Not Quite PTP";
    requires = [ "network-online.target" ];
    after = [ "network.target" "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.nqptp}/bin/nqptp";
      User = "nqptp";
      Group = "nqptp";
      AmbientCapabilities = "CAP_NET_BIND_SERVICE";
      Restart = "on-failure";
    };
  };

  # shairport-sync runs as an Austin user service via Home Manager so it can
  # order against the actual user PipeWire/Pulse units. Keep system-level
  # support here limited to nqptp, Avahi, and firewall openings.

  # Enable Avahi mDNS/Bonjour for AirPlay service discovery.
  services.avahi = {
    enable = true;
    publish.enable = true;
    publish.userServices = true;
    nssmdns4 = false;
    nssmdns6 = false;
  };

  # Enable AirPlay video mirroring (UxPlay — manual launch via `uxplay`)
  environment.systemPackages = with pkgs; [
    uxplay
  ];

  # AirPlay 2 firewall ports:
  # - TCP 5000 + UDP 6001-6011 for AirPlay 1 compatibility
  # - TCP 7000 for AirPlay 2 RTSP/PTP
  # - UDP 319-320 for nqptp PTP timing
  # - UDP 6000-6009 + TCP/UDP 32768-60999 for AirPlay 2 audio data
  #   (dynamically allocated, must allow the full ephemeral range)
  # See: https://github.com/mikebrady/shairport-sync/blob/master/TROUBLESHOOTING.md
  networking.firewall.allowedTCPPorts = [ 5000 7000 ];
  networking.firewall.allowedUDPPortRanges = [
    { from = 319; to = 320; } # nqptp PTP timing
    { from = 6000; to = 6009; } # AirPlay 2 audio control
    { from = 32768; to = 60999; } # AirPlay 2 audio data stream
  ];
  networking.firewall.allowedTCPPortRanges = [
    { from = 32768; to = 60999; } # AirPlay 2 audio data (control channel)
  ];

  # Increase download-buffer to 1GB
  # Rebuilds on Siberia should be an exclusive activity
  nix.settings.download-buffer-size = 1000000000;

  # Allow the insecure broadcom-sta package for WiFi
  nixpkgs.config.permittedInsecurePackages = [
    "broadcom-sta-6.30.223.271-59-6.12.91"
  ];

  # Use new OpenGL renderer on old MacBook Pro
  environment.variables = {
    GSK_RENDERER = "ngl";
  };
  # Use the systemd-boot EFI boot loader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Define hostname
  networking.hostName = "Siberia";

  # Enable webcam support
  hardware.facetimehd.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  system.stateVersion = "25.05";
}
