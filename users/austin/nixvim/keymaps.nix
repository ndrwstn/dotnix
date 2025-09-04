# users/austin/nixvim/keymaps.nix
{
  keymaps = [
    { key = "jk"; mode = "i"; action = "<ESC>"; options.desc = "Use \"jk\" to exit (escape) insert mode."; }

    # Buffer Navigation
    { key = "<leader>bn"; mode = "n"; action = "<cmd>bnext<CR>"; options.desc = "Next Buffer"; }
    { key = "<leader>bp"; mode = "n"; action = "<cmd>bprevious<CR>"; options.desc = "Previous Buffer"; }
    { key = "<leader>bx"; mode = "n"; action = "<cmd>bdelete<CR>"; options.desc = "Delete Buffer"; }

    # Tab Navigation
    { key = "<leader>tc"; mode = "n"; action = "<cmd>tabnew<CR>"; options.desc = "Create Tab"; }
    { key = "<leader>tn"; mode = "n"; action = "<cmd>tabnext<CR>"; options.desc = "Next Tab"; }
    { key = "<leader>tp"; mode = "n"; action = "<cmd>tabprevious<CR>"; options.desc = "Previous Tab"; }
    { key = "<leader>tu"; mode = "n"; action = "<cmd>tabnew %<CR>"; options.desc = "Duplicate Tab"; }
    { key = "<leader>tx"; mode = "n"; action = "<cmd>tabclose<CR>"; options.desc = "Delete Tab"; }

    # # Window Management
    # { key = "<leader>s="; mode = "n"; action = "<cmd>resize<CR>"; options.desc = "Equalize Splits"; }
    # { key = "<leader>sh"; mode = "n"; action = "<cmd>split<CR>"; options.desc = "Horizontal Split"; }
    # { key = "<leader>sv"; mode = "n"; action = "<cmd>vsplit<CR>"; options.desc = "Verticle Split"; }
    # { key = "<leader>sx"; mode = "n"; action = "<cmd>close<CR>"; options.desc = "Delete Split"; }

    # Harpoon
    # { key = "<leader>hh"; mode = "n"; action = "<cmd>Telescope harpoon marks<CR>"; options.desc = "Show Marks (Harpoon Telescope)"; }
    { key = "<leader>h1"; mode = "n"; action = "<cmd>lua require('harpoon'):list():select(1)<CR>"; options.desc = "Go to mark 1 (Harpoon)"; }
    { key = "<leader>h2"; mode = "n"; action = "<cmd>lua require('harpoon'):list():select(2)<CR>"; options.desc = "Go to mark 2 (Harpoon)"; }
    { key = "<leader>h3"; mode = "n"; action = "<cmd>lua require('harpoon'):list():select(3)<CR>"; options.desc = "Go to mark 3 (Harpoon)"; }
    { key = "<leader>h4"; mode = "n"; action = "<cmd>lua require('harpoon'):list():select(4)<CR>"; options.desc = "Go to mark 4 (Harpoon)"; }
    { key = "<leader>ha"; mode = "n"; action = "<cmd>lua require('harpoon'):list():add()<CR>"; options.desc = "Add File (Harpoon)"; }
    { key = "<leader>hm"; mode = "n"; action = "<cmd>lua require('harpoon').ui:toggle_quick_menu(require('harpoon'):list())<CR>"; options.desc = "Toggle Quick Menu (Harpoon)"; }
    { key = "<leader>hn"; mode = "n"; action = "<cmd>lua require('harpoon'):list():next()<CR>"; options.desc = "Next Mark (Harpoon)"; }
    { key = "<leader>hp"; mode = "n"; action = "<cmd>lua require('harpoon'):list():prev()<CR>"; options.desc = "Previous Mark (Harpoon)"; }

    # Neotree
    { key = "<leader>ef"; mode = "n"; action = "<cmd>Neotree action=focus source=filesystem position=left<CR>"; options.desc = "Show Files (Neotree)"; }
    { key = "<leader>er"; mode = "n"; action = "<cmd>Neotree action=focus source=filesystem reveal=true position=left<CR>"; options.desc = "Reveal File (Neotree)"; }
    { key = "<leader>ex"; mode = "n"; action = "<cmd>Neotree action=close source=filesystem position=left<CR>"; options.desc = "Close Files (Neotree)"; }



    # Telescope
    { key = "<leader>f?"; mode = "n"; action = "<cmd>Telescope help_tags<CR>"; options.desc = "Find Help (Telescope)"; }
    { key = "<leader>fb"; mode = "n"; action = "<cmd>Telescope buffers<CR>"; options.desc = "Find Buffers (Telescope)"; }
    { key = "<leader>ff"; mode = "n"; action = "<cmd>Telescope find_files<CR>"; options.desc = "Find Files (Telescope)"; }
    { key = "<leader>fg"; mode = "n"; action = "<cmd>Telescope live_grep<CR>"; options.desc = "Find Grep (Telescope)"; }
    { key = "<leader>fh"; mode = "n"; action = "<cmd>Telescope harpoon marks<CR>"; options.desc = "Find Marks (Telescope)"; }
    { key = "<leader>fp"; mode = "n"; action = "<cmd>Telescope projects<CR>"; options.desc = "Find Projects (Telescope)"; }
    { key = "<leader>fr"; mode = "n"; action = "<cmd>Telescope frecency<CR>"; options.desc = "Find Recent/Frequent (Telescope)"; }

    # Undotree
    # === Undotree window navigation (defaults) ===
    # j/k - Move up/down in history
    # <CR> - Jump to selected state  
    # p - Preview diff of selected state
    # q - Close undotree window
    { key = "<leader>u"; mode = "n"; action = "<cmd>UndotreeToggle<CR>"; options.desc = "Toggle Undotree"; }

    # Todo Comments
    # === Todo navigation (defaults) ===
    # ]t - Jump to next todo comment
    # [t - Jump to previous todo comment
    { key = "<leader>xt"; mode = "n"; action = "<cmd>TodoQuickFix<CR>"; options.desc = "Todo Quickfix List"; }

    # nvim-surround (all defaults, no custom mappings needed)
    # === Normal mode ===
    # ys{motion}{char} - Add surround (e.g., ysiw" to surround word with quotes)
    # yss{char} - Surround entire line
    # ds{char} - Delete surround (e.g., ds" to remove quotes)
    # cs{old}{new} - Change surround (e.g., cs"' to change " to ')
    # === Visual mode ===
    # S{char} - Surround selection
    # gS{char} - Surround selection on new lines

    # nvim-autopairs (automatic, no keybindings)
    # Automatically pairs: ( ) [ ] { } " " ' ' ` `
    # <CR> - Smart indent when pressing enter between pairs
    # <BS> - Delete both pairs when backspacing

    # Miscellaneous
    { key = "<leader>qf"; mode = "n"; action = "<cmd>Format<CR>"; options.desc = "Format Buffer (Conform)"; }
  ];
}
