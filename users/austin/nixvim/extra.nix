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
    -- TODO: Integrate blink.cmp with nvim-autopairs
    -- Design Decision: blink.cmp has different integration than nvim-cmp
    -- Need to research blink.cmp autopairs integration method
    --
    -- Old nvim-cmp integration (REMOVED):
    -- local cmp_autopairs = require('nvim-autopairs.completion.cmp')
    -- local cmp = require('cmp')
    -- cmp.event:on('confirm_done', cmp_autopairs.on_confirm_done())
    --
    -- New blink.cmp integration:
    -- Check blink.cmp documentation for autopairs integration
    -- Placeholder for future implementation
  '';
}
