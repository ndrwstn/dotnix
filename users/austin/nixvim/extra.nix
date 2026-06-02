# users/austin/nixvim/extra.nix
{ pkgs, unstable, config }:
{
  extraPlugins = with pkgs.vimPlugins; [
    # codewindow-nvim — DISABLED for NixOS 26.05 compat:
    # This plugin depends on nvim-treesitter-legacy which shares
    # pname="nvim-treesitter" with the new nvim-treesitter (main branch)
    # from plugins.treesitter.enable = true. The vim-utils assertion
    # prevents installing both. Removed in favor of treesitter module.
    # codewindow-nvim
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


