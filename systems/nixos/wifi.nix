{ pkgs, ... }:

{
  systemd.services.astn-wifi = {
    description = "Provision configured Wi-Fi NetworkManager profile";
    after = [ "NetworkManager.service" "agenix.service" ];
    requires = [ "NetworkManager.service" ];
    wantedBy = [ "multi-user.target" ];

    path = with pkgs; [
      coreutils
      jq
      networkmanager
    ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };

    script = ''
      secretFile="/run/agenix/general"
      connectionUuid="0fbc99c6-070c-4f6a-9a2d-bdf9e59d7eaa"

      if [ ! -f "$secretFile" ]; then
        echo "Shared secret $secretFile not found; skipping Wi-Fi setup."
        exit 0
      fi

      connectionId="$(jq -r '.wifi.home.id // empty' "$secretFile")"
      ssid="$(jq -r '.wifi.home.ssid // empty' "$secretFile")"
      psk="$(jq -r '.wifi.home.psk // empty' "$secretFile")"

      if [ -z "$connectionId" ] || [ -z "$ssid" ] || [ -z "$psk" ]; then
        echo "Wi-Fi credentials missing from $secretFile; skipping Wi-Fi setup."
        exit 0
      fi

      profileFile="$(mktemp /run/astn-wifi.XXXXXX)"
      trap 'rm -f "$profileFile"' EXIT
      chmod 0600 "$profileFile"

      {
        printf '[connection]\n'
        printf 'id=%s\n' "$connectionId"
        printf 'uuid=%s\n' "$connectionUuid"
        printf 'type=wifi\n'
        printf 'autoconnect=true\n'
        printf 'permissions=\n\n'

        printf '[wifi]\n'
        printf 'mode=infrastructure\n'
        printf 'ssid=%s\n\n' "$ssid"

        printf '[wifi-security]\n'
        printf 'auth-alg=open\n'
        printf 'key-mgmt=wpa-psk\n'
        printf 'psk=%s\n\n' "$psk"

        printf '[ipv4]\n'
        printf 'method=auto\n'
        printf 'dns-search=\n\n'

        printf '[ipv6]\n'
        printf 'addr-gen-mode=stable-privacy\n'
        printf 'method=auto\n'
        printf 'dns-search=\n'
      } > "$profileFile"

      nmcli connection load "$profileFile"
      nmcli connection reload
    '';
  };
}
