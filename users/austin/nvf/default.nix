# users/austin/nvf/default.nix
{
  config,
  pkgs,
}: {
  vim = {
    keymaps = import ./keymap.nix {inherit config pkgs;};
    useSystemClipboard = true;

    autocomplete = {
      blink-cmp = {
        enable = true;
      };
    };

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

    filetree = {
      neo-tree = {
        enable = true;
      };
    };

    formatter = {
      conform-nvim = {
        enable = true;
      };
    };

    git = {
      gitsigns = {
        enable = true;
      };
    };

    minimap.codewindow = {
      enable = true;
    };

    notify = {
      nvim-notify = {
        enable = true;
      };
    };

    projects = {
      project-nvim = {
        enable = true;
        setupOpts = {
          # manualMode = false;
          detectionMethods = ["lsp" "pattern" "git"];
          patterns = [".git" "flake.nix"];
          # lsp_ignored = [];
          # exclude_dirs = [];
          # show_hidden = false;
          # silent_chdir = true;
          # scope_chdir = "global";
        };
      };
    };

    snippets = {
      luasnip = {
        enable = true;
      };
    };

    statusline.lualine = {
      enable = true;
    };

    tabline.nvimBufferline = {
      enable = true;
    };

    telescope = {
      enable = true;
    };

    treesitter = {
      context = {
        enable = true;
      };
    };

    ui = {
      noice = {
        enable = true;
      };
    };

    # vim options
    options = {
      # tabs
      tabstop = 2;
      softtabstop = 2;
      shiftwidth = 2;
      expandtab = true;

      # line numbers
      number = true;
      relativenumber = true;

      # line wrapping
      wrap = true;
      linebreak = true;
      breakindent = true;
      showbreak = "↪ ";
      # splitright = true;
      # splitleft = true;
      signcolumn = "yes";

      # guifont
      guifont = "Inconsolata Nerd Font:h17";
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
