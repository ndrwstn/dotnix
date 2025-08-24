# users/austin/nixvim/extra.nix
{ pkgs }: {
  extraPlugins = with pkgs.vimPlugins; [
    codewindow-nvim
    nvim-notify
    train-nvim
    wrapping-nvim
  ];

  extraConfigLua = ''
    require('wrapping').setup {
      softener = {
        tex = true;
        latex = true;
      },
    }
    require('codewindow').setup {}
    -- require('train').setup {}
    vim.notify = require("notify")
  '';
}
