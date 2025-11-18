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
        # Design Decision: Using "default" preset with <C-CR> override for accept
        # Default preset provides: <C-n>/<C-p> navigate, <C-y> accept, <C-e> cancel
        # Override: <C-CR> for accept (preferred over <C-y>)
        keymap = {
          preset = "default";
          # TODO: Verify which syntax works - array or __raw function
          "<C-CR>" = [ "accept" "fallback" ];
        };

        appearance = {
          nerd_font_variant = "mono";
        };

        sources = {
          default = [ "lsp" "path" "snippets" "buffer" ];
        };

        cmdline = {
          sources = [ "buffer" "cmdline" ];
        };

        completion = {
          list = {
            selection = {
              preselect = true;
              auto_insert = true;
            };
          };
          menu = {
            auto_show = true;
            border = "rounded";
          };
          documentation = {
            auto_show = true;
            auto_show_delay_ms = 500;
          };
        };

        fuzzy = {
          # Typo resistance is built into the Rust fuzzy algorithm (no config needed)
          use_frecency = true; # Boosts recently/frequently used items
          use_proximity = true; # Boosts items in current buffer
          # Note: max_items and sorts may not be available in nixvim's blink.cmp version
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
    gitsigns = {
      enable = true;
      settings = {
        signs = {
          add = { text = "▎"; };
          change = { text = "▎"; };
          delete = { text = ""; };
          topdelete = { text = ""; };
          changedelete = { text = "▎"; };
          untracked = { text = "▎"; };
        };
      };
    };

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
      settings = {
        labels = "asdfghjklqwertyuiopzxcvbnm";
        search = {
          multi_window = true;
          mode = "exact";
        };
        jump = {
          jumplist = true;
          autojump = false;
        };
        label = {
          uppercase = true;
          current = true;
          after = true;
          before = false;
        };
        modes = {
          search = { enabled = false; };
          char = {
            enabled = true;
            jump_labels = false;
            # TODO: Consider customizing keys if non-standard motions needed
            # Note: nixvim requires attribute set format { f = {}; F = {}; }, not list [ "f" "F" ]
            # Default keys are: f, F, t, T, ;, , (standard vim motions)
          };
        };
      };
    };

    tmux-navigator.enable = true;

    # ============================================================================
    # LSP CONFIGURATION
    # ============================================================================
    lsp = {
      enable = true;

      # Integrate blink.cmp capabilities with LSP
      capabilities = ''
        require('blink.cmp').get_lsp_capabilities()
      '';

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
          # Note: Cannot use preset = "compact" because it includes 'startup' section
          # which requires lazy.nvim (not available in nixvim)
          # Custom sections that work without lazy.nvim:
          sections = [
            { section = "header"; }
            { section = "keys"; gap = 1; padding = 1; }
            # Excluded: { section = "startup"; } - requires lazy.nvim
          ];
        };

        picker = {
          enabled = true;
          # Flash integration for label jumping in picker
          win = {
            input = {
              keys = {
                "<a-s>" = {
                  action = "flash";
                  mode = [ "n" "i" ];
                };
              };
            };
          };
        };

        explorer = {
          enabled = true;
        };

        # Utilities
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
        zen = { enabled = true; };
      };
    };

    # ============================================================================
    # STATUSLINE & UI
    # ============================================================================
    lualine.enable = true;
    noice.enable = true;

    # Design Decision: REMOVED dressing.nvim - using snacks.input instead
    # Snacks provides input/select UI that replaces dressing functionality

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
        # TODO: Evaluate iCloud path for vault - may want local path instead
        # Current: iCloud sync'd vault (may have sync conflicts if editing on multiple devices)
        # Alternative: Local vault with manual sync or git
        # TODO: Consider enabling daily_notes, templates, completion features when workflow is established
        workspaces = [
          {
            name = "Primary";
            path = "~/Library/Mobile Documents/iCloud~md~obsidian/Documents/Primary";
          }
        ];
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
        providers = {
          usages = {
            enabled = true;
          };
          git_blame = {
            enabled = true;
          };
        };
      };
    };

    # Design Decision: persistence.nvim for automatic session management
    # Complements snacks.picker.projects() for project switching
    persistence = {
      enable = true;
      settings = {
        dir = {
          __raw = ''vim.fn.expand(vim.fn.stdpath("state") .. "/sessions/")'';
        };
        options = [ "buffers" "curdir" "tabpages" "winsize" ];
      };
    };

    # Design Decision: REMOVED zen-mode.nvim - using snacks.zen instead
    # Snacks provides zen mode with better integration

    # ============================================================================
    # AI & ASSISTANCE - COPILOT
    # ============================================================================
    # Design Decision: Using copilot-lua for GitHub Copilot integration
    # Provides inline AI suggestions and satisfies sidekick.nvim dependency
    # TODO: Consider adding blink-cmp-copilot integration in the future
    #       This would show Copilot suggestions in completion menu alongside LSP
    #       Requires: extraPlugin for blink-cmp-copilot (not in nixpkgs)
    #       See: https://github.com/giuxtaposition/blink-cmp-copilot
    #       Decision: Skipped for now to avoid extraPlugin maintenance burden
    copilot-lua = {
      enable = true;
      settings = {
        suggestion = {
          enabled = true;
          auto_trigger = true;
          debounce = 75;
          keymap = {
            accept = "<Tab>";
            accept_word = false;
            accept_line = false;
            next = "<M-]>";
            prev = "<M-[>";
            dismiss = "<C-]>";
          };
        };
        panel = {
          enabled = true;
          auto_refresh = false;
          keymap = {
            jump_prev = "[[";
            jump_next = "]]";
            accept = "<CR>";
            refresh = "gr";
            open = "<M-CR>";
          };
        };
        filetypes = {
          # Minimal disable list - only help files
          # TODO: Expand this list as needed (gitcommit, yaml, markdown, etc.)
          help = false;
          # Enable for all other filetypes by default
          "*" = true;
        };
      };
    };

    # ============================================================================
    # AI & ASSISTANCE - SIDEKICK
    # ============================================================================
    # Design Decision: sidekick.nvim leverages existing Copilot subscription
    # for NES (Next Edit Suggestions) and OpenCode CLI integration
    # Requires: copilot-lua (configured above) or copilot LSP server
    sidekick = {
      enable = true;
      settings = {
        # Next Edit Suggestions (NES) - Multi-line refactorings from Copilot
        nes = {
          enabled = true;
          debounce = 100;
          diff = {
            inline = "words";
          };
          trigger = {
            events = [ "ModeChanged i:n" "TextChanged" "User SidekickNesDone" ];
          };
          clear = {
            events = [ "TextChangedI" "InsertEnter" ];
            esc = true;
          };
        };

        # OpenCode CLI Integration
        cli = {
          watch = true;
          mux = {
            backend = "tmux";
            enabled = true;
            create = "terminal";
          };
          tools = {
            opencode = {
              cmd = [ "opencode" ];
              env = {
                OPENCODE_THEME = "system";
              };
            };
          };
          win = {
            layout = "right";
            split = {
              width = 80;
              height = 20;
            };
          };
          picker = "snacks";
          prompts = {
            explain = "Explain {this}";
            fix = "Can you fix {this}?";
            tests = "Can you write tests for {this}?";
          };
        };

        # Copilot status tracking
        copilot = {
          status = {
            enabled = true;
            level.__raw = "vim.log.levels.WARN";
          };
        };
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
      };
    };

    # ============================================================================
    # CODE OVERVIEW
    # ============================================================================
    # Design Decision: codewindow.nvim provides minimap for code overview
    # Note: Configured as extraPlugin in extra.nix (not a native nixvim module)
    # Keybinding: <leader>tm to toggle minimap

    # ============================================================================
    # TEXT MANIPULATION
    # ============================================================================
    # Auto-pairs for automatic bracket/quote closing
    nvim-autopairs = {
      enable = true;
      settings = {
        check_ts = true;
        ts_config = {
          lua = [ "string" ];
          javascript = [ "template_string" ];
        };
        disable_filetype = [ "TelescopePrompt" "vim" ];
        fast_wrap = {
          map = "<M-e>";
          chars = [ "{" "[" "(" "\"" "'" ];
          end_key = "$";
          keys = "qwertyuiopzxcvbnmasdfghjkl";
          check_comma = true;
          highlight = "Search";
          highlight_grey = "Comment";
        };
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
