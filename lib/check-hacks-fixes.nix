{ lib, vicinae }:

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

  msitools = import ../overlays/msitools.nix { inherit mkHack; };
  vicinaeHack = import ../overlays/vicinae.nix { inherit mkHack; inherit vicinae; };

  naphthalene = mkHack {
    name = "naphthalene-build-parallelism";
    reviewAfter = "2027-03-01";
    description = "Naphthalene's build concurrency and memory ceiling are pinned to its 12 GiB container (cores = 3, client maxJobs = 2, user.slice MemoryHigh/MemoryMax).";
  };

  all = [ msitools.hack vicinaeHack.hack naphthalene ];

  warningsFor = hacks: map (hack: hack.warning) hacks;
in
{
  inherit all naphthalene;

  nixos = {
    overlays = [ msitools.overlay vicinaeHack.overlay ];
    warnings = warningsFor [ msitools.hack vicinaeHack.hack ];
  };

  darwin = {
    overlays = [ ];
    warnings = [ ];
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
