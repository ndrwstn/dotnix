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

    -- TODO: Consider moving TeX-specific autopairs rules into a dedicated module
    local Rule = require('nvim-autopairs.rule')

    -- TeX/LaTeX: asymmetric backtick/apostrophe pairing and apostrophe behavior
    npairs.add_rule(Rule("`", "'", { "tex", "latex" }))
    npairs.add_rule(Rule("``", string.rep("'", 2), { "tex", "latex" }))

    local quote_rules = npairs.get_rules("'")
    if quote_rules and quote_rules[1] then
      quote_rules[1].not_filetypes = { "tex", "latex" }
    end

    -- ========================================================================
    -- SIDEKICK.NVIM - ENABLE COPILOT LSP
    -- ========================================================================
    -- Required for NES (Next Edit Suggestions) feature
    -- Note: Requires active GitHub Copilot subscription
    -- Sign in with: :LspCopilotSignIn
    vim.lsp.enable("copilot")
  '';
}
