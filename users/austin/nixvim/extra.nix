# users/austin/nixvim/extra.nix
{ pkgs }: {
  extraPlugins = with pkgs.vimPlugins; [
    codewindow-nvim
    nvim-notify # Keep for snacks.notifier integration
    wrapping-nvim
    undotree
    # train-nvim removed - replaced by hardtime.nvim
    luasnip # Snippet engine for blink.cmp
    opencode-nvim
  ];

  extraConfigLua = ''
    -- Configure opencode.nvim
    vim.g.opencode_opts = {
      -- Use snacks picker (already enabled)
      preferred_picker = "snacks",
      -- Auto-reload buffers when opencode edits files
      auto_reload = true,
      -- Use embedded terminal mode
      terminal = {
        width = 0.5,
      },
    }
  '';
}







