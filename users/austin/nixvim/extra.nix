# users/austin/nixvim/extra.nix
{ pkgs }: {
  extraPlugins = with pkgs.vimPlugins; [
    codewindow-nvim
    nvim-notify # Keep for snacks.notifier integration
    wrapping-nvim
    undotree
    # train-nvim removed - replaced by hardtime.nvim
  ];

  extraConfigLua = ''
    -- ========================================================================
    -- WRAPPING CONFIGURATION
    -- ========================================================================
    require('wrapping').setup {
      softener = {
        tex = true;
        latex = true;
      },
    }
    
    -- ========================================================================
    -- CODEWINDOW (MINIMAP) CONFIGURATION
    -- ========================================================================
    require('codewindow').setup {}
    -- TODO: Add keybinding to toggle minimap in keymaps.nix
    
    -- ========================================================================
    -- NOTIFY INTEGRATION WITH SNACKS
    -- ========================================================================
    vim.notify = require("notify")

    -- ========================================================================
    -- UNDOTREE CONFIGURATION
    -- ========================================================================
    vim.g.undotree_WindowLayout = 2
    vim.g.undotree_ShortIndicators = 1
    vim.g.undotree_SetFocusWhenToggle = 1

    -- ========================================================================
    -- BLINK.CMP INTEGRATION WITH NVIM-AUTOPAIRS
    -- ========================================================================
    -- Integrate autopairs with blink.cmp for smart <CR> behavior
    local cmp = require('blink.cmp')
    local npairs = require('nvim-autopairs')

    vim.keymap.set('i', '<CR>', function()
      if cmp.is_visible() then
        return cmp.accept()
      else
        return npairs.autopairs_cr()
      end
    end, { expr = true, replace_keycodes = false })
  '';
}
