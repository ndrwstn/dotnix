# systems/darwin/homebrew.nix
{
  config,
  pkgs,
  ...
}: {
  # Add homebrew to system PATH
  environment.systemPath =
    if pkgs.stdenv.isAarch64
    then [
      "/opt/homebrew/bin"
      "/opt/homebrew/sbin"
    ]
    else [
      "/usr/local/bin"
      "/usr/local/sbin"
    ];
}

