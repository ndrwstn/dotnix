{ lib, vicinae, nixpkgsUnstable }:

let
  mkHack =
    { name
    , reviewAfter
    , description
    , ...
    }:
    {
      inherit name reviewAfter description;
      warning = "Temporary workaround (${name}): ${description} Recheck upstream after ${reviewAfter}.";
    };

  thrift = import ../overlays/thrift-darwin.nix { inherit mkHack; };
  msitools = import ../overlays/msitools.nix { inherit mkHack; };
  vicinaeHack = import ../overlays/vicinae.nix { inherit mkHack; inherit vicinae; };
  solaar = import ../overlays/solaar.nix {
    inherit lib mkHack nixpkgsUnstable;
  };

  naphthalene = mkHack {
    name = "naphthalene-build-parallelism";
    reviewAfter = "2026-12-01";
    description = "Naphthalene's build parallelism is capped for the shared remote builder.";
  };

  all = [ thrift.hack msitools.hack vicinaeHack.hack solaar.hack naphthalene ];

  warningsFor = hacks: map (hack: hack.warning) hacks;
in
{
  inherit all naphthalene;

  nixos = {
    overlays = [ msitools.overlay vicinaeHack.overlay solaar.overlay ];
    overlaysWithoutSolaar = [ msitools.overlay vicinaeHack.overlay ];
    warnings = warningsFor [ msitools.hack vicinaeHack.hack solaar.hack ];
  };

  darwin = {
    overlays = [ thrift.overlay ];
    warnings = warningsFor [ thrift.hack ];
  };

  check =
    { today
    }:
    let
      expired = builtins.filter
        (hack: builtins.compareVersions today hack.reviewAfter > 0)
        all;
    in
    if expired == [ ]
    then true
    else throw "Nix workaround review dates have passed: ${lib.concatStringsSep ", " (map (hack: "${hack.name} (${hack.reviewAfter})") expired)}";
}
