# users/austin/nixvim/keymaps.nix
{
  keymaps = [
    # ========================================================================
    # BASIC MAPPINGS
    # ========================================================================
    { key = "jk"; mode = "i"; action = "<ESC>"; options.desc = "Use \"jk\" to exit (escape) insert mode."; }

    # ========================================================================
    # BUFFER NAVIGATION
    # ========================================================================
    { key = "<leader>bn"; mode = "n"; action = "<cmd>bnext<CR>"; options.desc = "Next Buffer"; }
    { key = "<leader>bp"; mode = "n"; action = "<cmd>bprevious<CR>"; options.desc = "Previous Buffer"; }
    { key = "<leader>bd"; mode = "n"; action = "<cmd>lua Snacks.bufdelete()<CR>"; options.desc = "Delete Buffer"; }
    # TODO: Audit other keymaps using 'x' suffix - may need to change to 'd' for consistency

    # ========================================================================
    # TAB NAVIGATION
    # ========================================================================
    { key = "<leader>tc"; mode = "n"; action = "<cmd>tabnew<CR>"; options.desc = "Create Tab"; }
    { key = "<leader>tn"; mode = "n"; action = "<cmd>tabnext<CR>"; options.desc = "Next Tab"; }
    { key = "<leader>tp"; mode = "n"; action = "<cmd>tabprevious<CR>"; options.desc = "Previous Tab"; }
    { key = "<leader>tu"; mode = "n"; action = "<cmd>tabnew %<CR>"; options.desc = "Duplicate Tab"; }
    { key = "<leader>tx"; mode = "n"; action = "<cmd>tabclose<CR>"; options.desc = "Delete Tab"; }

    # ========================================================================
    # HARPOON - FILE MARKING & NAVIGATION
    # ========================================================================
    { key = "<leader>h1"; mode = "n"; action = "<cmd>lua require('harpoon'):list():select(1)<CR>"; options.desc = "Go to mark 1 (Harpoon)"; }
    { key = "<leader>h2"; mode = "n"; action = "<cmd>lua require('harpoon'):list():select(2)<CR>"; options.desc = "Go to mark 2 (Harpoon)"; }
    { key = "<leader>h3"; mode = "n"; action = "<cmd>lua require('harpoon'):list():select(3)<CR>"; options.desc = "Go to mark 3 (Harpoon)"; }
    { key = "<leader>h4"; mode = "n"; action = "<cmd>lua require('harpoon'):list():select(4)<CR>"; options.desc = "Go to mark 4 (Harpoon)"; }
    { key = "<leader>ha"; mode = "n"; action = "<cmd>lua require('harpoon'):list():add()<CR>"; options.desc = "Add File (Harpoon)"; }
    { key = "<leader>hm"; mode = "n"; action = "<cmd>lua require('harpoon').ui:toggle_quick_menu(require('harpoon'):list())<CR>"; options.desc = "Toggle Quick Menu (Harpoon)"; }
    { key = "<leader>hn"; mode = "n"; action = "<cmd>lua require('harpoon'):list():next()<CR>"; options.desc = "Next Mark (Harpoon)"; }
    { key = "<leader>hp"; mode = "n"; action = "<cmd>lua require('harpoon'):list():prev()<CR>"; options.desc = "Previous Mark (Harpoon)"; }

    # ========================================================================
    # LSP KEYBINDINGS
    # ========================================================================
    # Design Decision: Using snacks.picker for LSP navigation (arbitrarily chosen)
    # TODO: Evaluate snacks.picker vs native LSP (vim.lsp.buf.*) someday
    # Snacks provides: fuzzy filtering, preview, consistent UI
    # Native provides: faster, simpler, built-in quickfix integration

    # Navigation
    { key = "gd"; mode = "n"; action = "<cmd>lua Snacks.picker.lsp_definitions()<CR>"; options.desc = "Goto Definition"; }
    { key = "gr"; mode = "n"; action = "<cmd>lua Snacks.picker.lsp_references()<CR>"; options.desc = "References"; }
    { key = "gI"; mode = "n"; action = "<cmd>lua Snacks.picker.lsp_implementations()<CR>"; options.desc = "Implementations"; }
    { key = "gy"; mode = "n"; action = "<cmd>lua Snacks.picker.lsp_type_definitions()<CR>"; options.desc = "Type Definition"; }

    # Actions
    { key = "K"; mode = "n"; action = "<cmd>lua vim.lsp.buf.hover()<CR>"; options.desc = "Hover Documentation"; }
    { key = "<leader>ca"; mode = [ "n" "v" ]; action = "<cmd>lua vim.lsp.buf.code_action()<CR>"; options.desc = "Code Action"; }
    { key = "<leader>rn"; mode = "n"; action = "<cmd>lua vim.lsp.buf.rename()<CR>"; options.desc = "Rename"; }
    { key = "<leader>sh"; mode = "n"; action = "<cmd>lua vim.lsp.buf.signature_help()<CR>"; options.desc = "Signature Help"; }

    # Diagnostics
    { key = "[d"; mode = "n"; action = "<cmd>lua vim.diagnostic.goto_prev()<CR>"; options.desc = "Previous Diagnostic"; }
    { key = "]d"; mode = "n"; action = "<cmd>lua vim.diagnostic.goto_next()<CR>"; options.desc = "Next Diagnostic"; }
    { key = "<leader>de"; mode = "n"; action = "<cmd>lua vim.diagnostic.open_float()<CR>"; options.desc = "Diagnostic Float"; }
    { key = "<leader>sd"; mode = "n"; action = "<cmd>lua Snacks.picker.diagnostics()<CR>"; options.desc = "Diagnostics (Picker)"; }
    { key = "<leader>ss"; mode = "n"; action = "<cmd>lua Snacks.picker.lsp_symbols()<CR>"; options.desc = "LSP Symbols"; }

    # ========================================================================
    # FLASH.NVIM - ENHANCED NAVIGATION
    # ========================================================================
    { key = "s"; mode = [ "n" "x" "o" ]; action = "<cmd>lua require('flash').jump()<CR>"; options.desc = "Flash Jump"; }
    { key = "S"; mode = [ "n" "x" "o" ]; action = "<cmd>lua require('flash').treesitter()<CR>"; options.desc = "Flash Treesitter"; }
    { key = "r"; mode = "o"; action = "<cmd>lua require('flash').remote()<CR>"; options.desc = "Remote Flash"; }
    { key = "R"; mode = [ "o" "x" ]; action = "<cmd>lua require('flash').treesitter_search()<CR>"; options.desc = "Treesitter Search"; }
    { key = "<c-s>"; mode = "c"; action = "<cmd>lua require('flash').toggle()<CR>"; options.desc = "Toggle Flash Search"; }

    # ========================================================================
    # GITSIGNS - GIT INTEGRATION
    # ========================================================================
    # Hunk Navigation (expression mappings)
    {
      mode = "n";
      key = "]c";
      action.__raw = ''
        function()
          if vim.wo.diff then return ']c' end
          vim.schedule(function() require('gitsigns').nav_hunk('next') end)
          return '<Ignore>'
        end
      '';
      options = { expr = true; desc = "Next Hunk"; };
    }
    {
      mode = "n";
      key = "[c";
      action.__raw = ''
        function()
          if vim.wo.diff then return '[c' end
          vim.schedule(function() require('gitsigns').nav_hunk('prev') end)
          return '<Ignore>'
        end
      '';
      options = { expr = true; desc = "Previous Hunk"; };
    }

    # Actions
    { key = "<leader>hs"; mode = "n"; action = "<cmd>Gitsigns stage_hunk<CR>"; options.desc = "Stage Hunk"; }
    { key = "<leader>hr"; mode = "n"; action = "<cmd>Gitsigns reset_hunk<CR>"; options.desc = "Reset Hunk"; }
    { key = "<leader>hs"; mode = "v"; action = ":Gitsigns stage_hunk<CR>"; options.desc = "Stage Hunk"; }
    { key = "<leader>hr"; mode = "v"; action = ":Gitsigns reset_hunk<CR>"; options.desc = "Reset Hunk"; }
    { key = "<leader>hS"; mode = "n"; action = "<cmd>Gitsigns stage_buffer<CR>"; options.desc = "Stage Buffer"; }
    { key = "<leader>hu"; mode = "n"; action = "<cmd>Gitsigns undo_stage_hunk<CR>"; options.desc = "Undo Stage Hunk"; }
    { key = "<leader>hR"; mode = "n"; action = "<cmd>Gitsigns reset_buffer<CR>"; options.desc = "Reset Buffer"; }
    { key = "<leader>hp"; mode = "n"; action = "<cmd>Gitsigns preview_hunk<CR>"; options.desc = "Preview Hunk"; }
    { key = "<leader>hb"; mode = "n"; action = "<cmd>Gitsigns blame_line<CR>"; options.desc = "Blame Line"; }
    { key = "<leader>hd"; mode = "n"; action = "<cmd>Gitsigns diffthis<CR>"; options.desc = "Diff This"; }

    # ========================================================================
    # SNACKS.NVIM - PICKER
    # ========================================================================
    { key = "<leader><space>"; mode = "n"; action = "<cmd>lua Snacks.picker.smart()<CR>"; options.desc = "Smart Picker"; }
    { key = "<leader>,"; mode = "n"; action = "<cmd>lua Snacks.picker.buffers()<CR>"; options.desc = "Buffers"; }
    { key = "<leader>/"; mode = "n"; action = "<cmd>lua Snacks.picker.grep()<CR>"; options.desc = "Grep"; }
    { key = "<leader>ff"; mode = "n"; action = "<cmd>lua Snacks.picker.files()<CR>"; options.desc = "Find Files"; }
    { key = "<leader>fr"; mode = "n"; action = "<cmd>lua Snacks.picker.recent()<CR>"; options.desc = "Recent Files"; }
    { key = "<leader>fb"; mode = "n"; action = "<cmd>lua Snacks.picker.buffers()<CR>"; options.desc = "Find Buffers"; }
    { key = "<leader>fg"; mode = "n"; action = "<cmd>lua Snacks.picker.grep()<CR>"; options.desc = "Grep"; }
    { key = "<leader>f?"; mode = "n"; action = "<cmd>lua Snacks.picker.help()<CR>"; options.desc = "Help"; }

    # ========================================================================
    # SNACKS.NVIM - EXPLORER
    # ========================================================================
    { key = "<leader>e"; mode = "n"; action = "<cmd>lua Snacks.explorer()<CR>"; options.desc = "Explorer"; }
    { key = "<leader>E"; mode = "n"; action = "<cmd>lua Snacks.explorer({ cwd = vim.fn.expand('%:p:h') })<CR>"; options.desc = "Explorer (Current Dir)"; }

    # ========================================================================
    # SNACKS.NVIM - GIT
    # ========================================================================
    { key = "<leader>gB"; mode = [ "n" "v" ]; action = "<cmd>lua Snacks.gitbrowse()<CR>"; options.desc = "Git Browse"; }

    # ========================================================================
    # SNACKS.NVIM - UTILITIES
    # ========================================================================
    { key = "<leader>z"; mode = "n"; action = "<cmd>lua Snacks.zen()<CR>"; options.desc = "Zen Mode"; }
    { key = "<leader>Z"; mode = "n"; action = "<cmd>lua Snacks.zen.zoom()<CR>"; options.desc = "Zoom"; }
    { key = "<leader>."; mode = "n"; action = "<cmd>lua Snacks.scratch()<CR>"; options.desc = "Scratch Buffer"; }
    { key = "<leader>S"; mode = "n"; action = "<cmd>lua Snacks.scratch.select()<CR>"; options.desc = "Select Scratch"; }
    { key = "<leader>n"; mode = "n"; action = "<cmd>lua Snacks.notifier.show_history()<CR>"; options.desc = "Notification History"; }
    { key = "<leader>un"; mode = "n"; action = "<cmd>lua Snacks.notifier.hide()<CR>"; options.desc = "Dismiss Notifications"; }
    { key = "<c-/>"; mode = [ "n" "t" ]; action = "<cmd>lua Snacks.terminal()<CR>"; options.desc = "Terminal"; }

    # ========================================================================
    # UNDOTREE - UNDO HISTORY VISUALIZATION
    # ========================================================================
    { key = "<leader>u"; mode = "n"; action = "<cmd>UndotreeToggle<CR>"; options.desc = "Toggle Undotree"; }
    # === Undotree window navigation (defaults) ===
    # j/k - Move up/down in history
    # <CR> - Jump to selected state  
    # p - Preview diff of selected state
    # q - Close undotree window

    # ========================================================================
    # TODO COMMENTS
    # ========================================================================
    { key = "<leader>xt"; mode = "n"; action = "<cmd>TodoQuickFix<CR>"; options.desc = "Todo Quickfix List"; }
    # === Todo navigation (defaults) ===
    # ]t - Jump to next todo comment
    # [t - Jump to previous todo comment

    # ========================================================================
    # NVIM-SURROUND (ALL DEFAULTS, NO CUSTOM MAPPINGS NEEDED)
    # ========================================================================
    # === Normal mode ===
    # ys{motion}{char} - Add surround (e.g., ysiw" to surround word with quotes)
    # yss{char} - Surround entire line
    # ds{char} - Delete surround (e.g., ds" to remove quotes)
    # cs{old}{new} - Change surround (e.g., cs"' to change " to ')
    # === Visual mode ===
    # S{char} - Surround selection
    # gS{char} - Surround selection on new lines

    # ========================================================================
    # NVIM-AUTOPAIRS (AUTOMATIC, NO KEYBINDINGS)
    # ========================================================================
    # Automatically pairs: ( ) [ ] { } " " ' ' ` `
    # <CR> - Smart indent when pressing enter between pairs (integrated with blink.cmp in extra.nix)
    # <BS> - Delete both pairs when backspacing
    # <M-e> - Fast wrap (surround with bracket/quote)

    # ========================================================================
    # MISCELLANEOUS
    # ========================================================================
    { key = "<leader>qf"; mode = "n"; action = "<cmd>Format<CR>"; options.desc = "Format Buffer (Conform)"; }
  ];
}
