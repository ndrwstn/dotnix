{ config
, pkgs
, lib
, ...
}:
let
  printerName = "Brother_MFC_L8900";
  printerHost = "brother.impetuo.us";
  printerPort = "631";
  printerSecretPath = "/run/agenix/general";
  printerKey = "brother_mfc_l8900";
  printerUnavailableMessage = "Info: Brother printer is unavailable; skipping printer setup.";
in
{
  system.activationScripts.postActivation.text = lib.mkAfter ''
    if [ ! -f "${printerSecretPath}" ]; then
      echo "Printer secret ${printerSecretPath} not found; skipping printer setup."
      exit 0
    fi

    printerUri="$(${pkgs.jq}/bin/jq -r '.printers.${printerKey}.uri' "${printerSecretPath}")"
    if [ -z "$printerUri" ] || [ "$printerUri" = "null" ]; then
      echo "Printer URI not found in ${printerSecretPath}; skipping printer setup."
      exit 0
    fi

    if ! ${pkgs.nmap}/bin/ncat -z -w 2 "${printerHost}" "${printerPort}"; then
      echo "${printerUnavailableMessage}"
      exit 0
    fi

    if /usr/sbin/lpadmin -p "${printerName}" -v "$printerUri" -m everywhere -E; then
      /usr/sbin/lpadmin -d "${printerName}" || \
        echo "Info: Could not set ${printerName} as the default printer."
    else
      echo "Info: Could not configure ${printerName}; skipping printer setup."
    fi
  '';
}
