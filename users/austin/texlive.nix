# users/austin/texlive.nix
{ pkgs }:
pkgs.texlive.combine {
  inherit
    (pkgs.texlive)
    scheme-minimal
    luatex
    latexmk
    # Core functionality
    latex-bin
    l3kernel
    l3packages
    xkeyval
    # Basic packages
    babel-english
    lualatex-math
    unicode-math
    graphics
    texcount
    # Document elements
    amsmath
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
    pdfpages
    datetime2
    datetime2-english
    fmtcount
    pgfopts
    multirow
    makecell
    nowidow
    xpeek
    xurl
    pdflscape
    epstopdf
    epstopdf-pkg
    # Resume
    moderncv
    luatexbase
    # ragged2e
    changepage
    # Formatter
    latexindent
    ;
}
