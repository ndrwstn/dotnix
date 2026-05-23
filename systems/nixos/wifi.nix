{ pkgs, ... }:

{
  systemd.services.astn-wifi = {
    description = "Provision configured Wi-Fi NetworkManager profiles";
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
      legacyConnectionId="astn-home-wifi"
      legacyConnectionUuid="0fbc99c6-070c-4f6a-9a2d-bdf9e59d7eaa"

      if [ ! -f "$secretFile" ]; then
        echo "Shared secret $secretFile not found; skipping Wi-Fi setup."
        exit 0
      fi

      networkCount="$(jq -r '.wifi.networks // [] | length' "$secretFile")"
      if [ "$networkCount" -eq 0 ]; then
        echo "No Wi-Fi networks configured in $secretFile; skipping Wi-Fi setup."
        exit 0
      fi

      is_desired_connection_id() {
        jq -e --arg id "$1" \
          '.wifi.networks // [] | any(.[]; .id == $id)' \
          "$secretFile" >/dev/null
      }

      if nmcli connection show "$legacyConnectionId" >/dev/null 2>&1; then
        echo "Removing legacy Wi-Fi connection $legacyConnectionId."
        nmcli connection delete "$legacyConnectionId"
      fi

      legacyUuidConnectionId="$(nmcli -g connection.id connection show "$legacyConnectionUuid" 2>/dev/null || true)"
      if [ -n "$legacyUuidConnectionId" ] && ! is_desired_connection_id "$legacyUuidConnectionId"; then
        echo "Removing legacy Wi-Fi connection UUID $legacyConnectionUuid."
        nmcli connection delete "$legacyConnectionUuid"
      fi

      jq -c '.wifi.networks // [] | .[]' "$secretFile" | while IFS= read -r network; do
        connectionId="$(printf '%s' "$network" | jq -r '.id // empty')"
        ssid="$(printf '%s' "$network" | jq -r '.ssid // empty')"
        psk="$(printf '%s' "$network" | jq -r '.psk // empty')"

        if [ -z "$connectionId" ] || [ -z "$ssid" ] || [ -z "$psk" ]; then
          echo "Skipping Wi-Fi network with missing id, ssid, or psk."
          continue
        fi

        if ! nmcli connection show "$connectionId" >/dev/null 2>&1; then
          nmcli connection add \
            type wifi \
            con-name "$connectionId" \
            ifname "*" \
            ssid "$ssid"
        fi

        nmcli connection modify "$connectionId" \
          connection.autoconnect yes \
          802-11-wireless.mode infrastructure \
          802-11-wireless.ssid "$ssid" \
          802-11-wireless-security.auth-alg open \
          802-11-wireless-security.key-mgmt wpa-psk \
          802-11-wireless-security.psk "$psk" \
          ipv4.method auto \
          ipv6.addr-gen-mode stable-privacy \
          ipv6.method auto
      done
    '';
  };
}
