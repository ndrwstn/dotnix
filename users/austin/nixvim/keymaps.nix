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
    { key = "<leader>bx"; mode = "n"; action = "<cmd>bdelete<CR>"; options.desc = "Delete Buffer"; }

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
    # TODO: SNACKS.NVIM - FILE EXPLORER
    # ========================================================================
    # Design Decision: Migrated from neo-tree to snacks.explorer (TRIAL BASIS)
    # snacks.explorer uses picker paradigm instead of tree view
    #
    # OLD neo-tree keybindings (REMOVED):
    # <leader>ef - Show Files (Neotree)
    # <leader>er - Reveal File (Neotree)
    # <leader>ex - Close Files (Neotree)
    #
    # TODO: Add snacks.explorer keybindings:
    # { key = "<leader>e"; mode = "n"; action = "<cmd>lua Snacks.explorer()<CR>"; options.desc = "Explorer (Snacks)"; }
    # { key = "<leader>E"; mode = "n"; action = "<cmd>lua Snacks.explorer({ cwd = vim.fn.expand('%:p:h') })<CR>"; options.desc = "Explorer (Current Dir)"; }

    # ========================================================================
    # TODO: SNACKS.NVIM - FUZZY FINDER / PICKER
    # ========================================================================
    # Design Decision: Migrated from telescope to snacks.picker (TRIAL BASIS)
    #
    # OLD telescope keybindings (REMOVED):
    # <leader>f? - Find Help (Telescope)
    # <leader>fb - Find Buffers (Telescope)
    # <leader>ff - Find Files (Telescope)
    # <leader>fg - Find Grep (Telescope)
    # <leader>fh - Find Marks (Telescope)
    # <leader>fp - Find Projects (Telescope)
    # <leader>fr - Find Recent/Frequent (Telescope)
    #
    # TODO: Add snacks.picker keybindings:
    # File Finding
    # { key = "<leader>ff"; mode = "n"; action = "<cmd>lua Snacks.picker.files()<CR>"; options.desc = "Find Files (Snacks)"; }
    # { key = "<leader>fr"; mode = "n"; action = "<cmd>lua Snacks.picker.recent()<CR>"; options.desc = "Recent Files (Snacks)"; }
    # { key = "<leader>fb"; mode = "n"; action = "<cmd>lua Snacks.picker.buffers()<CR>"; options.desc = "Find Buffers (Snacks)"; }
    # { key = "<leader>fg"; mode = "n"; action = "<cmd>lua Snacks.picker.grep()<CR>"; options.desc = "Grep (Snacks)"; }
    # { key = "<leader>fp"; mode = "n"; action = "<cmd>lua Snacks.picker.projects()<CR>"; options.desc = "Projects (Snacks)"; }
    # { key = "<leader>f?"; mode = "n"; action = "<cmd>lua Snacks.picker.help()<CR>"; options.desc = "Help (Snacks)"; }
    # { key = "<leader>fh"; mode = "n"; action = "<cmd>lua Snacks.picker.harpoon()<CR>"; options.desc = "Harpoon Marks (Snacks)"; }

    # ========================================================================
    # TODO: GIT KEYBINDINGS (SNACKS + DIFFVIEW)
    # ========================================================================
    # Design Decision: Combining snacks.picker for Git operations with
    # diffview.nvim for advanced diff viewing
    #
    # TODO: Add Git keybindings:
    # { key = "<leader>gb"; mode = "n"; action = "<cmd>lua Snacks.picker.git_branches()<CR>"; options.desc = "Git Branches"; }
    # { key = "<leader>gl"; mode = "n"; action = "<cmd>lua Snacks.picker.git_log()<CR>"; options.desc = "Git Log"; }
    # { key = "<leader>gs"; mode = "n"; action = "<cmd>lua Snacks.picker.git_status()<CR>"; options.desc = "Git Status"; }
    # { key = "<leader>gd"; mode = "n"; action = "<cmd>DiffviewOpen<CR>"; options.desc = "Diff View"; }
    # { key = "<leader>gh"; mode = "n"; action = "<cmd>DiffviewFileHistory<CR>"; options.desc = "File History"; }
    # { key = "<leader>gB"; mode = "n"; action = "<cmd>lua Snacks.gitbrowse()<CR>"; options.desc = "Git Browse"; }

    # ========================================================================
    # TODO: LSP KEYBINDINGS (SNACKS.PICKER)
    # ========================================================================
    # Design Decision: Using snacks.picker for LSP operations instead of
    # telescope or built-in LSP pickers
    #
    # TODO: Add LSP keybindings:
    # { key = "gd"; mode = "n"; action = "<cmd>lua Snacks.picker.lsp_definitions()<CR>"; options.desc = "Goto Definition"; }
    # { key = "gr"; mode = "n"; action = "<cmd>lua Snacks.picker.lsp_references()<CR>"; options.desc = "References"; }
    # { key = "gi"; mode = "n"; action = "<cmd>lua Snacks.picker.lsp_implementations()<CR>"; options.desc = "Implementations"; }
    # { key = "<leader>ss"; mode = "n"; action = "<cmd>lua Snacks.picker.lsp_symbols()<CR>"; options.desc = "LSP Symbols"; }
    # { key = "<leader>sd"; mode = "n"; action = "<cmd>lua Snacks.picker.diagnostics()<CR>"; options.desc = "Diagnostics"; }

    # ========================================================================
    # TODO: NEW PLUGIN KEYBINDINGS
    # ========================================================================

    # TODO: Codewindow (minimap)
    # { key = "<leader>tm"; mode = "n"; action = "<cmd>lua require('codewindow').toggle_minimap()<CR>"; options.desc = "Toggle Minimap"; }

    # TODO: Hardtime (training)
    # { key = "<leader>th"; mode = "n"; action = "<cmd>Hardtime toggle<CR>"; options.desc = "Toggle Hardtime"; }
    # { key = "<leader>hr"; mode = "n"; action = "<cmd>Hardtime report<CR>"; options.desc = "Hardtime Report"; }

    # TODO: Zen Mode
    # { key = "<leader>z"; mode = "n"; action = "<cmd>ZenMode<CR>"; options.desc = "Toggle Zen Mode"; }

    # TODO: Flash (motion)
    # { key = "s"; mode = "n"; action = "<cmd>lua require('flash').jump()<CR>"; options.desc = "Flash Jump"; }
    # { key = "S"; mode = "n"; action = "<cmd>lua require('flash').treesitter()<CR>"; options.desc = "Flash Treesitter"; }

    # TODO: Persistence (sessions)
    # { key = "<leader>qs"; mode = "n"; action = "<cmd>lua require('persistence').load()<CR>"; options.desc = "Restore Session"; }
    # { key = "<leader>ql"; mode = "n"; action = "<cmd>lua require('persistence').load({ last = true })<CR>"; options.desc = "Restore Last Session"; }
    # { key = "<leader>qd"; mode = "n"; action = "<cmd>lua require('persistence').stop()<CR>"; options.desc = "Don't Save Session"; }

    # TODO: Snacks utilities
    # { key = "<leader>."; mode = "n"; action = "<cmd>lua Snacks.scratch()<CR>"; options.desc = "Scratch Buffer"; }
    # { key = "<leader>S"; mode = "n"; action = "<cmd>lua Snacks.scratch.select()<CR>"; options.desc = "Select Scratch"; }
    # { key = "<leader>n"; mode = "n"; action = "<cmd>lua Snacks.notifier.show_history()<CR>"; options.desc = "Notification History"; }
    # { key = "<leader>bd"; mode = "n"; action = "<cmd>lua Snacks.bufdelete()<CR>"; options.desc = "Delete Buffer (Snacks)"; }
    # { key = "<leader>un"; mode = "n"; action = "<cmd>lua Snacks.notifier.hide()<CR>"; options.desc = "Dismiss Notifications"; }

    # TODO: Sidekick.nvim (AI assistant)
    # Research sidekick.nvim documentation for recommended keybindings
    # Provides: Copilot NES, OpenCode integration

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
    # <CR> - Smart indent when pressing enter between pairs
    # <BS> - Delete both pairs when backspacing

    # ========================================================================
    # MISCELLANEOUS
    # ========================================================================
    { key = "<leader>qf"; mode = "n"; action = "<cmd>Format<CR>"; options.desc = "Format Buffer (Conform)"; }
  ];
}
