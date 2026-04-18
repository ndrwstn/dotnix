{ pkgs
, lib
, autopkgs
, ...
}: {
  # Apple Silicon-specific user configuration lives here.
  home.packages = [
    autopkgs.ocrit
  ];
}
