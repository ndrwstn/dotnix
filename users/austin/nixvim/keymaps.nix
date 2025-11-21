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
    # Navigation
    { key = "<leader>bn"; mode = "n"; action = "<cmd>bnext<CR>"; options.desc = "Next Buffer"; }
    { key = "<leader>bp"; mode = "n"; action = "<cmd>bprevious<CR>"; options.desc = "Previous Buffer"; }

    # Management
    { key = "<leader>bd"; mode = "n"; action = "<cmd>lua Snacks.bufdelete()<CR>"; options.desc = "Delete Buffer"; }
    { key = "<leader>bA"; mode = "n"; action = "<cmd>%bd|e#|bd#<CR>"; options.desc = "Close All Buffers"; }
    { key = "<leader>bO"; mode = "n"; action = "<cmd>%bd|e#<CR>"; options.desc = "Close Other Buffers"; }

    # List
    { key = "<leader>bl"; mode = "n"; action = "<cmd>lua Snacks.picker.buffers()<CR>"; options.desc = "List Buffers"; }

    # Quick Jump (browser-style)
    { key = "<leader>b1"; mode = "n"; action = "<cmd>BufferLineGoToBuffer 1<CR>"; options.desc = "Go to Buffer 1"; }
    { key = "<leader>b2"; mode = "n"; action = "<cmd>BufferLineGoToBuffer 2<CR>"; options.desc = "Go to Buffer 2"; }
    { key = "<leader>b3"; mode = "n"; action = "<cmd>BufferLineGoToBuffer 3<CR>"; options.desc = "Go to Buffer 3"; }
    { key = "<leader>b4"; mode = "n"; action = "<cmd>BufferLineGoToBuffer 4<CR>"; options.desc = "Go to Buffer 4"; }
    { key = "<leader>b5"; mode = "n"; action = "<cmd>BufferLineGoToBuffer 5<CR>"; options.desc = "Go to Buffer 5"; }
    { key = "<leader>b6"; mode = "n"; action = "<cmd>BufferLineGoToBuffer 6<CR>"; options.desc = "Go to Buffer 6"; }
    { key = "<leader>b7"; mode = "n"; action = "<cmd>BufferLineGoToBuffer 7<CR>"; options.desc = "Go to Buffer 7"; }
    { key = "<leader>b8"; mode = "n"; action = "<cmd>BufferLineGoToBuffer 8<CR>"; options.desc = "Go to Buffer 8"; }
    { key = "<leader>b9"; mode = "n"; action = "<cmd>BufferLineGoToBuffer 9<CR>"; options.desc = "Go to Buffer 9"; }
    # TODO: Audit other keymaps using 'x' suffix - may need to change to 'd' for consistency

    # ========================================================================
    # TAB NAVIGATION
    # ========================================================================
    { key = "<leader>tc"; mode = "n"; action = "<cmd>tabnew<CR>"; options.desc = "Create Tab"; }
    { key = "<leader>tn"; mode = "n"; action = "<cmd>tabnext<CR>"; options.desc = "Next Tab"; }
    { key = "<leader>tp"; mode = "n"; action = "<cmd>tabprevious<CR>"; options.desc = "Previous Tab"; }
    { key = "<leader>tu"; mode = "n"; action = "<cmd>tabnew %<CR>"; options.desc = "Duplicate Tab"; }
    { key = "<leader>td"; mode = "n"; action = "<cmd>tabclose<CR>"; options.desc = "Delete Tab"; }

    # ========================================================================
    # MARKS (Harpoon)
    # ========================================================================
    # Jump to marks
    { key = "<leader>m1"; mode = "n"; action = "<cmd>lua require('harpoon'):list():select(1)<CR>"; options.desc = "Go to Mark 1"; }
    { key = "<leader>m2"; mode = "n"; action = "<cmd>lua require('harpoon'):list():select(2)<CR>"; options.desc = "Go to Mark 2"; }
    { key = "<leader>m3"; mode = "n"; action = "<cmd>lua require('harpoon'):list():select(3)<CR>"; options.desc = "Go to Mark 3"; }
    { key = "<leader>m4"; mode = "n"; action = "<cmd>lua require('harpoon'):list():select(4)<CR>"; options.desc = "Go to Mark 4"; }
    { key = "<leader>m5"; mode = "n"; action = "<cmd>lua require('harpoon'):list():select(5)<CR>"; options.desc = "Go to Mark 5"; }
    { key = "<leader>m6"; mode = "n"; action = "<cmd>lua require('harpoon'):list():select(6)<CR>"; options.desc = "Go to Mark 6"; }
    { key = "<leader>m7"; mode = "n"; action = "<cmd>lua require('harpoon'):list():select(7)<CR>"; options.desc = "Go to Mark 7"; }
    { key = "<leader>m8"; mode = "n"; action = "<cmd>lua require('harpoon'):list():select(8)<CR>"; options.desc = "Go to Mark 8"; }
    { key = "<leader>m9"; mode = "n"; action = "<cmd>lua require('harpoon'):list():select(9)<CR>"; options.desc = "Go to Mark 9"; }

    # Mark management
    { key = "<leader>ma"; mode = "n"; action = "<cmd>lua require('harpoon'):list():add()<CR>"; options.desc = "Add File"; }
    { key = "<leader>mm"; mode = "n"; action = "<cmd>lua require('harpoon').ui:toggle_quick_menu(require('harpoon'):list())<CR>"; options.desc = "Menu"; }
    { key = "<leader>mn"; mode = "n"; action = "<cmd>lua require('harpoon'):list():next()<CR>"; options.desc = "Next Mark"; }
    { key = "<leader>mp"; mode = "n"; action = "<cmd>lua require('harpoon'):list():prev()<CR>"; options.desc = "Previous Mark"; }
    { key = "<leader>mD"; mode = "n"; action = "<cmd>lua require('harpoon'):list():remove()<CR>"; options.desc = "Delete Current"; }
    { key = "<leader>mC"; mode = "n"; action = "<cmd>lua require('harpoon'):list():clear()<CR>"; options.desc = "Clear All"; }

    # ========================================================================
    # LSP NAVIGATION (Neovim 0.10+ native gr* keys)
    # ========================================================================
    # Using Neovim's native gr* family to avoid overriding standard g* commands
    # Design Decision: Using snacks.picker for LSP navigation (arbitrarily chosen)
    # TODO: Evaluate snacks.picker vs native LSP (vim.lsp.buf.*) someday
    # Snacks provides: fuzzy filtering, preview, consistent UI
    # Native provides: faster, simpler, built-in quickfix integration
    { key = "gd"; mode = "n"; action = "<cmd>lua Snacks.picker.lsp_definitions()<CR>"; options.desc = "Goto Definition"; }
    { key = "grr"; mode = "n"; action = "<cmd>lua Snacks.picker.lsp_references()<CR>"; options.desc = "References"; }
    { key = "gri"; mode = "n"; action = "<cmd>lua Snacks.picker.lsp_implementations()<CR>"; options.desc = "Implementations"; }
    { key = "grt"; mode = "n"; action = "<cmd>lua Snacks.picker.lsp_type_definitions()<CR>"; options.desc = "Type Definition"; }

    # Note: Neovim 0.10+ also provides:
    # - gra (code action) - we use <leader>ca instead
    # - grn (rename) - we use <leader>cr instead
    # - gO (document symbols) - we use <leader>xs instead

    # ========================================================================
    # CODE ACTIONS (Affirmative)
    # ========================================================================
    { key = "<leader>ca"; mode = [ "n" "v" ]; action = "<cmd>lua vim.lsp.buf.code_action()<CR>"; options.desc = "Code Action"; }
    { key = "<leader>cr"; mode = "n"; action = "<cmd>lua vim.lsp.buf.rename()<CR>"; options.desc = "Rename"; }
    { key = "<leader>cf"; mode = "n"; action = "<cmd>Format<CR>"; options.desc = "Format"; }
    { key = "<leader>ch"; mode = "n"; action = "<cmd>lua vim.lsp.buf.signature_help()<CR>"; options.desc = "Signature Help"; }
    { key = "<leader>ci"; mode = "n"; action = "<cmd>lua vim.lsp.buf.hover()<CR>"; options.desc = "Info/Hover"; }

    # ========================================================================
    # DIAGNOSTICS NAVIGATION (Bracket keys)
    # ========================================================================
    { key = "[d"; mode = "n"; action = "<cmd>lua vim.diagnostic.goto_prev()<CR>"; options.desc = "Previous Diagnostic"; }
    { key = "]d"; mode = "n"; action = "<cmd>lua vim.diagnostic.goto_next()<CR>"; options.desc = "Next Diagnostic"; }

    # Note: Diagnostic lists, symbols, and LSP lists moved to <leader>x* (Trouble)

    # ========================================================================
    # FLASH.NVIM - ENHANCED NAVIGATION
    # ========================================================================
    { key = "s"; mode = [ "n" "x" "o" ]; action = "<cmd>lua require('flash').jump()<CR>"; options.desc = "Flash Jump"; }
    { key = "S"; mode = [ "n" "x" "o" ]; action = "<cmd>lua require('flash').treesitter()<CR>"; options.desc = "Flash Treesitter"; }
    { key = "r"; mode = "o"; action = "<cmd>lua require('flash').remote()<CR>"; options.desc = "Remote Flash"; }
    { key = "R"; mode = [ "o" "x" ]; action = "<cmd>lua require('flash').treesitter_search()<CR>"; options.desc = "Treesitter Search"; }
    { key = "<c-s>"; mode = "c"; action = "<cmd>lua require('flash').toggle()<CR>"; options.desc = "Toggle Flash Search"; }

    # ========================================================================
    # GIT OPERATIONS
    # ========================================================================
    # Hunk Navigation (bracket keys)
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

    # Git Viewing (Diffview)
    { key = "<leader>gd"; mode = "n"; action = "<cmd>DiffviewOpen<CR>"; options.desc = "Diff View"; }
    { key = "<leader>gh"; mode = "n"; action = "<cmd>DiffviewFileHistory %<CR>"; options.desc = "File History"; }
    { key = "<leader>gH"; mode = "n"; action = "<cmd>DiffviewFileHistory<CR>"; options.desc = "Repo History"; }
    { key = "<leader>gc"; mode = "n"; action = "<cmd>DiffviewClose<CR>"; options.desc = "Close Diffview"; }
    { key = "<leader>gB"; mode = [ "n" "v" ]; action = "<cmd>lua Snacks.gitbrowse()<CR>"; options.desc = "Browse"; }

    # Git Hunks (Gitsigns)
    { key = "<leader>gs"; mode = "n"; action = "<cmd>Gitsigns stage_hunk<CR>"; options.desc = "Stage Hunk"; }
    { key = "<leader>gr"; mode = "n"; action = "<cmd>Gitsigns reset_hunk<CR>"; options.desc = "Reset Hunk"; }
    { key = "<leader>gs"; mode = "v"; action = ":Gitsigns stage_hunk<CR>"; options.desc = "Stage Hunk"; }
    { key = "<leader>gr"; mode = "v"; action = ":Gitsigns reset_hunk<CR>"; options.desc = "Reset Hunk"; }
    { key = "<leader>gS"; mode = "n"; action = "<cmd>Gitsigns stage_buffer<CR>"; options.desc = "Stage Buffer"; }
    { key = "<leader>gu"; mode = "n"; action = "<cmd>Gitsigns undo_stage_hunk<CR>"; options.desc = "Undo Stage"; }
    { key = "<leader>gR"; mode = "n"; action = "<cmd>Gitsigns reset_buffer<CR>"; options.desc = "Reset Buffer"; }
    { key = "<leader>gp"; mode = "n"; action = "<cmd>Gitsigns preview_hunk<CR>"; options.desc = "Preview Hunk"; }
    { key = "<leader>gb"; mode = "n"; action = "<cmd>Gitsigns blame_line<CR>"; options.desc = "Blame Line"; }
    { key = "<leader>gf"; mode = "n"; action = "<cmd>Gitsigns diffthis<CR>"; options.desc = "Diff File"; }

    # ========================================================================
    # FIND/FILES (Picker)
    # ========================================================================
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
    # TOGGLES (UI & Tools)
    # ========================================================================
    { key = "<leader>Th"; mode = "n"; action = "<cmd>Hardtime toggle<CR>"; options.desc = "Hardtime"; }
    { key = "<leader>Tm"; mode = "n"; action = "<cmd>lua require('codewindow').toggle_minimap()<CR>"; options.desc = "Minimap"; }
    { key = "<leader>Tn"; mode = "n"; action = "<cmd>lua Snacks.notifier.hide()<CR>"; options.desc = "Dismiss Notifications"; }
    { key = "<leader>Tu"; mode = "n"; action = "<cmd>UndotreeToggle<CR>"; options.desc = "Undotree"; }
    { key = "<leader>Tz"; mode = "n"; action = "<cmd>lua Snacks.zen()<CR>"; options.desc = "Zen Mode"; }
    { key = "<leader>TZ"; mode = "n"; action = "<cmd>lua Snacks.zen.zoom()<CR>"; options.desc = "Zoom"; }

    # ========================================================================
    # UNDOTREE - UNDO HISTORY VISUALIZATION
    # ========================================================================
    # Toggled with <leader>Tu
    # === Undotree window navigation (defaults) ===
    # j/k - Move up/down in history
    # <CR> - Jump to selected state  
    # p - Preview diff of selected state
    # q - Close undotree window

    # ========================================================================
    # SNACKS.NVIM - UTILITIES
    # ========================================================================
    # TODO: Evaluate and organize snacks utility keybindings after gaining experience
    # Candidates: scratch buffer, notification history, terminal
    # Consider consolidating under <leader>s* prefix or keep scattered for quick access
    # { key = "<leader>."; mode = "n"; action = "<cmd>lua Snacks.scratch()<CR>"; options.desc = "Scratch Buffer"; }
    # { key = "<leader>S"; mode = "n"; action = "<cmd>lua Snacks.scratch.select()<CR>"; options.desc = "Select Scratch"; }
    # { key = "<leader>n"; mode = "n"; action = "<cmd>lua Snacks.notifier.show_history()<CR>"; options.desc = "Notification History"; }
    # { key = "<c-/>"; mode = [ "n" "t" ]; action = "<cmd>lua Snacks.terminal()<CR>"; options.desc = "Terminal"; }

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
    # TROUBLE - DIAGNOSTICS & LISTS
    # ========================================================================
    # TODO: After gaining experience, evaluate:
    #   - Whether to add Picker variants (xp for picker diagnostics, xS for picker symbols)
    #   - Whether Trouble-only approach is sufficient
    #   - Whether diagnostic float (xd) is redundant with xx/xX
    #   - Consider adding xr for References if frequently used
    # Current approach: Trouble-first (structured views), no Picker duplicates

    # Diagnostics
    { key = "<leader>xx"; mode = "n"; action = "<cmd>Trouble diagnostics toggle<CR>"; options.desc = "Diagnostics (All)"; }
    { key = "<leader>xX"; mode = "n"; action = "<cmd>Trouble diagnostics toggle filter.buf=0<CR>"; options.desc = "Diagnostics (Buffer)"; }
    { key = "<leader>xd"; mode = "n"; action = "<cmd>lua vim.diagnostic.open_float()<CR>"; options.desc = "Diagnostic Float"; }

    # Symbols & Lists
    { key = "<leader>xs"; mode = "n"; action = "<cmd>Trouble symbols toggle focus=false<CR>"; options.desc = "Symbols"; }
    { key = "<leader>xl"; mode = "n"; action = "<cmd>Trouble lsp toggle focus=false win.position=right<CR>"; options.desc = "LSP Lists"; }
    { key = "<leader>xL"; mode = "n"; action = "<cmd>Trouble loclist toggle<CR>"; options.desc = "Location List"; }
    { key = "<leader>xQ"; mode = "n"; action = "<cmd>Trouble qflist toggle<CR>"; options.desc = "Quickfix List"; }



    # ========================================================================
    # HARDTIME - MOTION TRAINING
    # ========================================================================
    # Toggled with <leader>Th

    # ========================================================================
    # SESSIONS/QUIT
    # ========================================================================
    # TODO: Consider adding after gaining experience:
    #   - <leader>qS - Save Session (manual save)
    #   - <leader>qf - Find/Select Session
    #   - <leader>qq - Quit
    #   - <leader>qQ - Quit All
    { key = "<leader>qs"; mode = "n"; action = "<cmd>lua require('persistence').load()<CR>"; options.desc = "Restore Session"; }
    { key = "<leader>ql"; mode = "n"; action = "<cmd>lua require('persistence').load({ last = true })<CR>"; options.desc = "Restore Last Session"; }
    { key = "<leader>qd"; mode = "n"; action = "<cmd>lua require('persistence').stop()<CR>"; options.desc = "Don't Save Current Session"; }

    # ========================================================================
    # SIDEKICK - COPILOT NES + OPENCODE CLI
    # ========================================================================
    # NES Navigation
    # { key = "<Tab>"; mode = [ "n" "i" ]; action.__raw = "function() return require('sidekick').nes_jump_or_apply() end"; options = { expr = true; desc = "NES Jump/Apply"; }; }

    # CLI Controls
    # { key = "<c-.>"; mode = [ "n" "t" "i" "x" ]; action = "<cmd>lua require('sidekick.cli').toggle()<CR>"; options.desc = "Toggle Sidekick CLI"; }
    # { key = "<leader>aa"; mode = "n"; action = "<cmd>lua require('sidekick.cli').toggle()<CR>"; options.desc = "Toggle Sidekick CLI"; }
    # { key = "<leader>as"; mode = "n"; action = "<cmd>lua require('sidekick.cli').select()<CR>"; options.desc = "Select CLI Tool"; }
    # { key = "<leader>ad"; mode = "n"; action = "<cmd>lua require('sidekick.cli').close()<CR>"; options.desc = "Close CLI"; }

    # Context Sending
    # { key = "<leader>at"; mode = [ "x" "n" ]; action = "<cmd>lua require('sidekick.cli').send({ msg = '{this}' })<CR>"; options.desc = "Send This"; }
    # { key = "<leader>af"; mode = "n"; action = "<cmd>lua require('sidekick.cli').send({ msg = '{file}' })<CR>"; options.desc = "Send File"; }
    # { key = "<leader>av"; mode = "x"; action = "<cmd>lua require('sidekick.cli').send({ msg = '{selection}' })<CR>"; options.desc = "Send Selection"; }
    # { key = "<leader>ap"; mode = [ "n" "x" ]; action = "<cmd>lua require('sidekick.cli').prompt()<CR>"; options.desc = "CLI Prompt"; }

    # Direct OpenCode Access
    # { key = "<leader>ac"; mode = "n"; action = "<cmd>lua require('sidekick.cli').toggle({ name = 'opencode', focus = true })<CR>"; options.desc = "OpenCode CLI"; }

    # ========================================================================
    # CODEWINDOW - MINIMAP
    # ========================================================================
    # Toggled with <leader>Tm

    # ========================================================================
    # MISCELLANEOUS
    # ========================================================================
    # (Empty - all keybindings now organized into semantic groups)
  ];
}
