# users/austin/nixvim/extra.nix
{ pkgs, unstable, config }: {
  extraPlugins = with pkgs.vimPlugins; [
    codewindow-nvim
    nvim-notify # Keep for snacks.notifier integration
    wrapping-nvim
    undotree
    # train-nvim removed - replaced by hardtime.nvim
    luasnip # Snippet engine for blink.cmp
  ];

  extraConfigLua = ''
    do
      local ok, result = pcall(dofile, vim.fn.expand("${config.xdg.configHome}/nvim/lua/generated/matugen.lua"))
      if ok and type(result) == "table" then
        local colors = result

        local ok_lualine, lualine = pcall(require, "lualine")
        if ok_lualine then
          lualine.setup({
            options = {
              theme = {
                normal = {
                  a = { bg = colors.accent, fg = colors.on_accent, gui = "bold" },
                  b = { bg = colors.surface_alt, fg = colors.fg },
                  c = { bg = colors.surface, fg = colors.fg },
                },
                insert = {
                  a = { bg = colors.accent_alt, fg = colors.bg, gui = "bold" },
                  b = { bg = colors.surface_alt, fg = colors.fg },
                },
                visual = {
                  a = { bg = colors.warn, fg = colors.bg, gui = "bold" },
                  b = { bg = colors.surface_alt, fg = colors.fg },
                },
                replace = {
                  a = { bg = colors.err, fg = colors.bg, gui = "bold" },
                  b = { bg = colors.surface_alt, fg = colors.fg },
                },
                inactive = {
                  a = { bg = colors.surface, fg = colors.muted },
                  b = { bg = colors.surface, fg = colors.muted },
                  c = { bg = colors.surface, fg = colors.muted },
                },
              },
            },
          })
        end
      end
    end
  '';
}






