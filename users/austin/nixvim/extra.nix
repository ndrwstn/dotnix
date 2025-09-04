# users/austin/nixvim/extra.nix
{ pkgs }: {
  extraPlugins = with pkgs.vimPlugins; [
    codewindow-nvim
    nvim-notify
    train-nvim
    wrapping-nvim
    undotree # Add this line
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

    -- Undotree configuration
    vim.g.undotree_WindowLayout = 2
    vim.g.undotree_ShortIndicators = 1
    vim.g.undotree_SetFocusWhenToggle = 1

    -- Integrate nvim-autopairs with cmp
    local cmp_autopairs = require('nvim-autopairs.completion.cmp')
    local cmp = require('cmp')
    cmp.event:on('confirm_done', cmp_autopairs.on_confirm_done())
  '';
}
