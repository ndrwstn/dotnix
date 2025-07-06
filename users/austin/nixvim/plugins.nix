# users/austin/nixvim/plugins.nix
{ pkgs }: {
  clipboard = { register = "unnamedplus"; };
  plugins = {

    alpha = {
      enable = true;
      theme = "dashboard";
    };

    bufferline = {
      enable = true;
      settings = {
        options = {
          diagnostics = "nvim_lsp";
          mode = "buffers";
          separator_style = "slant";
        };
      };
    };

    cmp = {
      enable = true;
      settings = {
        mapping = {
          "<C-@>" = "cmp.mapping.complete()";
          "<C-e>" = "cmp.mapping.close()";
          "<CR>" = "cmp.mapping.confirm({ select = true })";
          "<PageDown>" = "cmp.mapping.scroll_docs(4)";
          "<PageUp>" = "cmp.mapping.scroll_docs(-4)";
          "<S-Tab>" = "cmp.mapping.select_prev_item()";
          "<Tab>" = "cmp.mapping.select_next_item()";
        };
        sources = [
          { name = "nvim_lsp"; }
          { name = "luasnip"; }
          { name = "buffer"; }
          { name = "path"; }
        ];
      };
    };

    conform-nvim = {
      enable = true;
      settings = {
        format_on_save = {
          timeout_ms = 500;
          lsp_fallback = true;
        };
        formatters = {
          nixpkgs-fmt = {
            command = "nixpkgs-fmt";
          };
          sqlfluff = {
            command = "sqlfluff";
            args = [ "format" "--dialect" "postgres" "-" ];
          };
        };
        formatters_by_ft = {
          lua = [ "stylua" ];
          python = [ "isort" "black" ];
          nix = [ "nixpkgs-fmt" ];
          markdown = [ "prettier" ];
          sh = [ "shfmt" ];
          bash = [ "shfmt" ];
          json = [ "prettier" ];
          yaml = [ "prettier" ];
          toml = [ "taplo" ];
          sql = [ "sqlfluff" ];
          latex = [ "latexindent" ];
        };
      };
    };

    gitsigns.enable = true;
    harpoon = {
      enable = true;
      enableTelescope = true;
      # settings = {};
    };
    lsp = {
      enable = true;
      servers = {
        # tex
        texlab.enable = true;
        # nix
        nil_ls.enable = true;
        # python
        pyright.enable = true;
        # lua
        lua_ls.enable = true;
        # markdown
        marksman.enable = true;
        # sql
        sqlls = {
          enable = true;
          package = pkgs.sqls;
        };
      };
    };
    lualine.enable = true;
    luasnip.enable = true;
    neo-tree.enable = true;
    noice.enable = true;
    project-nvim = {
      enable = true;
      settings = {
        detection_methods = [ "lsp" "pattern" "git" ];
        patterns = [ ".git" "flake.nix" ".project-nvim" ];
      };
    };

    telescope = {
      enable = true;
      extensions = {
        fzf-native = {
          enable = true;
        };
        frecency = {
          enable = true;
        };
      };
    };

    treesitter = {
      enable = true;
      settings = {
        ensure_installed = [
          "nix"
          "markdown"
          "markdown_inline"
          "python"
          "sql"
          "lua"
          "latex"
          "bash"
          "json"
          "yaml"
          "diff"
          "toml"
        ];
      };
    };
    treesitter-context.enable = true;
    trouble = {
      enable = true;
    };
    vimtex = {
      enable = true;
      settings = {
        view = {
          method =
            if pkgs.stdenv.isDarwin
            then "skim"
            else "zathura";
        };
        compiler = {
          options = [
            "-lualatex"
            "-verbose"
            "-file-line-error"
            "-synctex=1"
            "-interaction=nonstopmode"
          ];
        };
      };
    };
    web-devicons.enable = true;
    which-key.enable = true;
  };
}
