# users/austin/texlive.nix
{pkgs}:
pkgs.texlive.combine {
  inherit
    (pkgs.texlive)
    scheme-minimal
    luatex
    latexmk
    # Core functionality
    latex-bin
    # Basic packages
    babel-english
    extsizes
    lualatex-math
    unicode-math
    # Document elements
    hyperref
    graphics
    geometry
    xcolor
    ;
}
