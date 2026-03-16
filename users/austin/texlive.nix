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
    l3build
    xkeyval
    # Basic packages
    babel-english
    lualatex-math
    unicode-math
    graphics
    texcount
    # Document elements
    amsmath
    datetime2
    datetime2-english
    enumitem
    epstopdf
    epstopdf-pkg
    extsizes
    fancyhdr
    fmtcount
    footmisc
    geometry
    hyperref
    lipsum
    makecell
    multirow
    nowidow
    nth
    pdflscape
    pdfpages
    pgfopts
    setspace
    titlesec
    xcolor
    xpeek
    xurl
    # Resume
    moderncv
    luatexbase
    # ragged2e
    changepage
    # Formatter
    latexindent
    # Linter
    chktex
    ;
}
