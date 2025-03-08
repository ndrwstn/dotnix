# users/austin/nvf/default.nix
{
  config,
  pkgs,
}: {
  vim = {
    keymaps = import ./keymap.nix {inherit config pkgs;};
    binds = {
      whichKey = {
        enable = true;
      };
      cheatsheet = {
        enable = true;
      };
    };
    dashboard.alpha = {
      enable = true;
    };
    tabline.nvimBufferline = {
      enable = true;
    };
    statusline.lualine = {
      enable = true;
    };
    useSystemClipboard = true;
    filetree = {
      neo-tree = {
        enable = true;
      };
    };
    treesitter = {
      context = {
        enable = true;
      };
    };
    telescope = {
      enable = true;
    };
    notify = {
      nvim-notify = {
        enable = true;
      };
    };
    options = {
      tabstop = 2;
      softtabstop = 2;
      shiftwidth = 2;
      expandtab = true;
      number = true;
      relativenumber = true;
      # splitright = true;
      # splitleft = true;
      signcolumn = "yes";
    };
    lsp = {
      enable = true;
      formatOnSave = true;
      lightbulb.enable = true;
      trouble.enable = true;
    };
    languages = {
      enableLSP = true;
      enableFormat = true;
      enableTreesitter = true;
      enableExtraDiagnostics = true;

      nix.enable = true;
      markdown.enable = true;
      python.enable = true;
      sql.enable = true;
      lua.enable = true;
    };
    extraPlugins = with pkgs.vimPlugins; {
      telescope-fzf-native = {
        package = telescope-fzf-native-nvim;
        setup = ''
          require('telescope').load_extension('fzf')
        '';
      };
      train = {
        package = train-nvim;
      };
    };
  };
}
