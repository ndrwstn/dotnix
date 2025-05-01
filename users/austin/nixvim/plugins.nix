# users/austin/nixvim/plugins.nix
{pkgs}: {
  clipboard = {register = "unnamedplus";};
  plugins = {
    cmp.enable = true;
    cmp.mapping.confirm = "<C-y>";
    which-key.enable = true;
    cheatsheet.enable = true;
    alpha.enable = true;
    neo-tree.enable = true;
    conform-nvim.enable = true;
    gitsigns.enable = true;
    codewindow.enable = true;
    nvim-notify.enable = true;
    project-nvim = {
      enable = true;
      detectionMethods = ["lsp" "pattern" "git"];
      patterns = [".git" "flake.nix" ".project-nvim"];
    };
    luasnip.enable = true;
    lualine.enable = true;
    bufferline.enable = true;
    telescope.enable = true;
    telescope.extensions.fzf-native.enable = true;
    treesitter-context.enable = true;
    noice.enable = true;
  };
}
