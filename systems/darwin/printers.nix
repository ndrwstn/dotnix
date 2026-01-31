{ config
, pkgs
, lib
, ...
}:
let
  printerName = "Brother_MFC_L8900";
  printerSecretPath = "/run/agenix/general";
  printerKey = "brother_mfc_l8900";
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

    /usr/sbin/lpadmin -p "${printerName}" -v "$printerUri" -m everywhere -E
    /usr/sbin/lpadmin -d "${printerName}"
  '';
}
