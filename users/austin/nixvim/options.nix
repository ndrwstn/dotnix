# users/austin/nixvim/options.nix
{
  options = {
    tabstop = 2;
    softtabstop = 2;
    shiftwidth = 2;
    expandtab = true;
    number = true;
    relativenumber = true;
    wrap = true;
    linebreak = true;
    breakindent = true;
    showbreak = "↪ ";
    signcolumn = "yes";
    guifont = "Inconsolata Nerd Font:h17";
  };
}
