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
    -- SIDEKICK.NVIM - ENABLE COPILOT LSP
    -- ========================================================================
    -- Required for NES (Next Edit Suggestions) feature
    -- Note: Requires active GitHub Copilot subscription
    -- Sign in with: :LspCopilotSignIn
    -- vim.lsp.enable("copilot")
  '';
}
