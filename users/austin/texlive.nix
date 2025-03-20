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
    lualatex-math
    unicode-math
    graphics
    # Document elements
    enumitem
    nth
    footmisc
    hyperref
    extsizes
    geometry
    titlesec
    xcolor
    setspace
    fancyhdr
    xkeyval
    pdfpages
    datetime2
    pgfopts
    multirow
    makecell
    nowidow
    xpeek
    xurl
    pdflscape
    epstopdf
    epstopdf-pkg
    ;
}
