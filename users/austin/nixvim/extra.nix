# users/austin/nixvim/extra.nix
{ pkgs, unstable, config }:
{
  extraPlugins = with pkgs.vimPlugins; [
    codewindow-nvim
    nvim-notify # Keep for snacks.notifier integration
    wrapping-nvim
    undotree
    # train-nvim removed - replaced by hardtime.nvim
    luasnip # Snippet engine for blink.cmp
  ];

  extraConfigLua = ''
    local prose_spell_group = vim.api.nvim_create_augroup("prose-spell", { clear = true })
    vim.api.nvim_create_autocmd("FileType", {
      group = prose_spell_group,
      pattern = { "gitcommit", "markdown", "plaintex", "tex", "text" },
      callback = function()
        vim.opt_local.spell = true
      end,
    })

  '';
}


