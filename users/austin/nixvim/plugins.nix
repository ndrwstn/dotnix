# users/austin/nixvim/plugins.nix
{ pkgs
, texlivePackage
,
}: {
  clipboard = { register = "unnamedplus"; };
  plugins = {

    # ============================================================================
    # COMPLETION ENGINE
    # ============================================================================
    # Design Decision: Migrated from nvim-cmp to blink.cmp for:
    # - Better performance (Rust-based fuzzy matching)
    # - Native vim.snippet support (no luasnip dependency)
    # - Simpler configuration
    # ============================================================================
    blink-cmp = {
      enable = true;
      settings = {
        # TODO: Finalize blink.cmp keybindings to match old nvim-cmp
        # Old mappings were:
        # <C-@> = complete()
        # <C-e> = close()
        # <CR> = confirm()
        # <PageDown> = scroll_docs(4)
        # <PageUp> = scroll_docs(-4)
        # <S-Tab> = select_prev()
        # <Tab> = select_next()
        keymap = {
          preset = "default";
        };

        sources = {
          default = [ "lsp" "path" "snippets" "buffer" ];
        };

        completion = {
          menu = {
            border = "rounded";
          };
          documentation = {
            auto_show = true;
            auto_show_delay_ms = 500;
          };
        };

        fuzzy = {
          use_typo_resistance = true;
          use_frecency = true;
          use_proximity = true;
        };
      };
    };

    # ============================================================================
    # UI & BUFFER MANAGEMENT
    # ============================================================================
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

    # ============================================================================
    # FORMATTING
    # ============================================================================
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
          python = [ "ruff" ];
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

    # ============================================================================
    # GIT INTEGRATION
    # ============================================================================
    gitsigns.enable = true;

    # Design Decision: Added diffview.nvim for advanced Git diff viewing
    # Complements gitsigns (which provides inline decorations)
    diffview = {
      enable = true;
      # TODO: Configure diffview keybindings in keymaps.nix
      # Provides: :DiffviewOpen, :DiffviewFileHistory
    };

    # ============================================================================
    # NAVIGATION & MOTION
    # ============================================================================
    harpoon = {
      enable = true;
      # Removed enableTelescope since we're migrating to snacks.picker
    };

    # Design Decision: flash.nvim provides significantly faster navigation
    # than default f/t/search motions with labeled jumps
    flash = {
      enable = true;
      # TODO: Configure flash.nvim keybindings in keymaps.nix
      # Default: s for forward search, S for backward
    };

    tmux-navigator.enable = true;

    # ============================================================================
    # LSP CONFIGURATION
    # ============================================================================
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

    # ============================================================================
    # SNACKS.NVIM - QoL UTILITIES COLLECTION
    # ============================================================================
    # Design Decision: Replacing telescope, neo-tree, alpha, project-nvim
    # This is a TRIAL BASIS migration - if picker/explorer don't work well,
    # we can revert to old/neovim-20251118 branch and restore telescope/neo-tree
    # ============================================================================
    snacks = {
      enable = true;
      settings = {
        # Core performance modules
        bigfile = { enabled = true; };
        quickfile = { enabled = true; };

        # UI Replacements (TRIAL BASIS)
        dashboard = {
          enabled = true;
          # TODO: Configure dashboard layout and sections
          # preset = "github";  # or "compact" or custom
        };

        picker = {
          enabled = true;
          # TODO: Configure picker keybindings in keymaps.nix
          # Replaces: telescope.nvim (TRIAL BASIS)
        };

        explorer = {
          enabled = true;
          # TODO: Configure explorer keybindings in keymaps.nix
          # Replaces: neo-tree.nvim (TRIAL BASIS)
          # Uses picker paradigm instead of tree view
        };

        # New capabilities
        words = { enabled = true; };
        gitbrowse = { enabled = true; };
        bufdelete = { enabled = true; };
        scroll = { enabled = true; };
        statuscolumn = { enabled = true; };
        indent = { enabled = true; };
        scope = { enabled = true; };
        input = { enabled = true; };
        terminal = { enabled = true; };
        scratch = { enabled = true; };
        rename = { enabled = true; };
        dim = { enabled = true; };
        notifier = { enabled = true; };

        # TODO: Configure styles for windows/notifications
        styles = {
          notification = {
            # wo = { wrap = true };
          };
        };
      };
    };

    # ============================================================================
    # STATUSLINE & UI
    # ============================================================================
    lualine.enable = true;
    noice.enable = true;

    # Design Decision: dressing.nvim enhances vim.ui.select/input
    # Integrates with snacks.picker for consistent UI
    dressing = {
      enable = true;
      # TODO: Configure dressing.nvim to use snacks backend
      # settings = {
      #   select = {
      #     backend = [ "snacks" "builtin" ];
      #   };
      # };
    };

    # ============================================================================
    # TREESITTER
    # ============================================================================
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

    # ============================================================================
    # DIAGNOSTICS & TROUBLE
    # ============================================================================
    trouble = {
      enable = true;
    };

    # ============================================================================
    # SPECIALIZED PLUGINS
    # ============================================================================
    # Markdown rendering
    render-markdown = {
      enable = true;
      settings = {
        preset = "none";
        enabled = true;
      };
    };

    # LaTeX support
    vimtex = {
      enable = true;
      texlivePackage = texlivePackage;
      settings = {
        view_method = (if pkgs.stdenv.isDarwin then "skim" else "zathura");
        compiler_latexmk = {
          options = [
            "-lualatex"
            "-verbose"
            "-file-line-error"
            "-synctex=1"
            "-interaction=nonstopmode"
          ];
        };
        quickfix_ignore_filters = [
          "Underfull"
          "Overfull"
        ];
      };
    };

    # Design Decision: obsidian.nvim for Obsidian-style note-taking
    # Works standalone without Obsidian app, requires .obsidian/ folder
    obsidian = {
      enable = true;
      settings = {
        # TODO: Configure vault directory
        # workspaces = [
        #   {
        #     name = "personal";
        #     path = "~/Documents/notes";
        #   }
        # ];
      };
    };

    # ============================================================================
    # PRODUCTIVITY & UTILITIES
    # ============================================================================
    web-devicons.enable = true;
    which-key.enable = true;

    # Design Decision: lensline.nvim shows LSP references, git blame, complexity
    # inline with code for at-a-glance context
    lensline = {
      enable = true;
      settings = {
        # TODO: Configure providers
        # Recommended: usages (LSP references), git_blame (last author)
        # Optional: complexity, diagnostics
      };
    };

    # Design Decision: persistence.nvim for automatic session management
    # Complements snacks.picker.projects() for project switching
    persistence = {
      enable = true;
      settings = {
        # TODO: Configure session directory and options
        # dir = vim.fn.expand(vim.fn.stdpath("state") .. "/sessions/");
        # options = [ "buffers" "curdir" "tabpages" "winsize" ];
      };
    };

    # Design Decision: zen-mode.nvim for distraction-free writing
    # Pairs well with vimtex and render-markdown
    zen-mode = {
      enable = true;
      settings = {
        # TODO: Configure zen-mode appearance
        # window = {
        #   width = 120;
        # };
      };
    };

    # ============================================================================
    # AI & ASSISTANCE
    # ============================================================================
    # Design Decision: sidekick.nvim leverages existing Copilot subscription
    # for NES (Next Edit Suggestions) and OpenCode CLI integration
    sidekick = {
      enable = true;
      settings = {
        # TODO: Configure sidekick.nvim
        # Requires: GitHub Copilot subscription (confirmed available)
        # OpenCode CLI already installed via opencode.packages
      };
    };

    # ============================================================================
    # TRAINING & MOTION IMPROVEMENT
    # ============================================================================
    # Design Decision: hardtime.nvim replaces train.nvim with more aggressive
    # training that blocks bad habits and suggests better motions
    hardtime = {
      enable = true;
      settings = {
        enabled = true; # Start enabled by default
        max_count = 3; # Allow 3 repetitions before blocking
        hint = true;
        notification = true;
        # TODO: Add toggle keybinding in keymaps.nix
      };
    };

    # ============================================================================
    # TEXT MANIPULATION
    # ============================================================================
    # Auto-pairs for automatic bracket/quote closing
    nvim-autopairs = {
      enable = true;
      settings = {
        check_ts = true;
        disable_filetype = [ "TelescopePrompt" "vim" ];
      };
    };

    # Highlight and search TODO/FIXME comments
    todo-comments = {
      enable = true;
      settings = {
        signs = true;
        keywords = {
          FIX = { icon = " "; color = "error"; alt = [ "FIXME" "BUG" "FIXIT" "ISSUE" ]; };
          TODO = { icon = " "; color = "info"; };
          HACK = { icon = " "; color = "warning"; };
          WARN = { icon = " "; color = "warning"; alt = [ "WARNING" "XXX" ]; };
          PERF = { icon = " "; alt = [ "OPTIM" "PERFORMANCE" "OPTIMIZE" ]; };
          NOTE = { icon = " "; color = "hint"; alt = [ "INFO" ]; };
          TEST = { icon = "⏲ "; color = "test"; alt = [ "TESTING" "PASSED" "FAILED" ]; };
        };
      };
    };

    # Surround text objects with quotes/brackets/tags
    nvim-surround = {
      enable = true;
      settings = {
        keymaps = {
          insert = "<C-g>s";
          insert_line = "<C-g>S";
          normal = "ys";
          normal_cur = "yss";
          normal_line = "yS";
          normal_cur_line = "ySS";
          visual = "S";
          visual_line = "gS";
          delete = "ds";
          change = "cs";
          change_line = "cS";
        };
      };
    };
  };
}
