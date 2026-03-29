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

        local transparent_bg = ${if pkgs.stdenv.isLinux then "true" else "false"}

        if transparent_bg then
          local set = vim.api.nvim_set_hl
          set(0, "Normal", { fg = colors.fg, bg = "NONE" })
          set(0, "NormalNC", { fg = colors.fg, bg = "NONE" })
          set(0, "EndOfBuffer", { fg = colors.bg, bg = "NONE" })
          set(0, "SignColumn", { bg = "NONE" })
          set(0, "FoldColumn", { bg = "NONE" })
          set(0, "LineNr", { fg = colors.muted, bg = "NONE" })
        end

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





