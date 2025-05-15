# users/austin/nixvim/options.nix
{
	opts = {
		tabstop = 2;
		softtabstop = 2;
		shiftwidth = 2;
		expandtab = true;
		number = true;
		relativenumber = true;
		termguicolors = true;
		mouse = "a";	
		linebreak = true;
		breakindent = true;
		showbreak = "↪ ";
		signcolumn = "yes";
		guifont = "Inconsolata Nerd Font:h17";
	};
    # wrap = true; # handled by wrapping-nvim in `./extra.nix`.
}
