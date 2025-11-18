# Group 1: Core Plugins Configuration - Implementation Guide

## Status: IN PROGRESS

This document tracks the implementation of Group 1 core plugin configurations for the Neovim overhaul.

## Completed Changes

### 1. blink.cmp ✅ PARTIAL

- Added `<C-CR>` keybinding for accept
- TODO: Add remaining configuration (appearance, sources.cmdline, completion.list)

### 2. snacks.nvim ❌ PENDING

- Need to add: preset="compact", zen module, flash integration in picker

### 3. Remove dressing.nvim & zen-mode.nvim ❌ PENDING

- Both plugins still enabled, need to remove

### 4. LSP Configuration ❌ PENDING

- Need to add blink.cmp capabilities integration

### 5. flash.nvim ❌ PENDING

- Need to add full settings configuration

### 6. gitsigns ❌ PENDING

- Need to add signs configuration

### 7. nvim-autopairs ❌ PENDING

- Need to add ts_config and fast_wrap

### 8. conform.nvim ✅ VERIFIED

- Already correctly configured with lsp_fallback=true

### 9. Keybindings ❌ PENDING

- All keybindings need to be added to keymaps.nix

## Remaining Work

### plugins.nix Changes Needed

```nix
# blink-cmp - ADD:
appearance = { nerd_font_variant = "mono"; };
sources.cmdline = [ "buffer" "cmdline" ];
completion.list.selection = { preselect = true; auto_insert = true; };
completion.menu.auto_show = true;

# snacks - UPDATE:
dashboard.preset = "compact";
picker.win.input.keys."<a-s>" = { action = "flash"; mode = [ "n" "i" ]; };
zen = { enabled = true; };

# dressing - REMOVE entire block (lines 223-233)
# zen-mode - REMOVE entire block (lines 343-353)

# LSP - ADD after enable = true:
capabilities = ''
  require('blink.cmp').get_lsp_capabilities()
'';

# flash - ADD settings:
settings = {
  labels = "asdfghjklqwertyuiopzxcvbnm";
  search = { multi_window = true; mode = "exact"; };
  jump = { jumplist = true; autojump = false; };
  label = { uppercase = true; current = true; after = true; before = false; };
  modes = {
    search = { enabled = false; };
    char = { enabled = true; jump_labels = false; keys = [ "f" "F" "t" "T" ";" "," ]; };
  };
};

# gitsigns - ADD settings:
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

# nvim-autopairs - ADD to settings:
ts_config = {
  lua = [ "string" ];
  javascript = [ "template_string" ];
};
fast_wrap = {
  map = "<M-e>";
  chars = [ "{" "[" "(" "\"" "'" ];
  end_key = "$";
  keys = "qwertyuiopzxcvbnmasdfghjkl";
  check_comma = true;
  highlight = "Search";
  highlight_grey = "Comment";
};
```

### keymaps.nix - All New Keybindings

```nix
# LSP (using snacks.picker)
{ key = "gd"; mode = "n"; action = "<cmd>lua Snacks.picker.lsp_definitions()<CR>"; options.desc = "Goto Definition"; }
{ key = "gr"; mode = "n"; action = "<cmd>lua Snacks.picker.lsp_references()<CR>"; options.desc = "References"; }
{ key = "gI"; mode = "n"; action = "<cmd>lua Snacks.picker.lsp_implementations()<CR>"; options.desc = "Implementations"; }
{ key = "gy"; mode = "n"; action = "<cmd>lua Snacks.picker.lsp_type_definitions()<CR>"; options.desc = "Type Definition"; }
{ key = "K"; mode = "n"; action = "<cmd>lua vim.lsp.buf.hover()<CR>"; options.desc = "Hover Documentation"; }
{ key = "<leader>ca"; mode = [ "n" "v" ]; action = "<cmd>lua vim.lsp.buf.code_action()<CR>"; options.desc = "Code Action"; }
{ key = "<leader>rn"; mode = "n"; action = "<cmd>lua vim.lsp.buf.rename()<CR>"; options.desc = "Rename"; }
{ key = "<leader>sh"; mode = "n"; action = "<cmd>lua vim.lsp.buf.signature_help()<CR>"; options.desc = "Signature Help"; }
{ key = "[d"; mode = "n"; action = "<cmd>lua vim.diagnostic.goto_prev()<CR>"; options.desc = "Previous Diagnostic"; }
{ key = "]d"; mode = "n"; action = "<cmd>lua vim.diagnostic.goto_next()<CR>"; options.desc = "Next Diagnostic"; }
{ key = "<leader>de"; mode = "n"; action = "<cmd>lua vim.diagnostic.open_float()<CR>"; options.desc = "Diagnostic Float"; }
{ key = "<leader>sd"; mode = "n"; action = "<cmd>lua Snacks.picker.diagnostics()<CR>"; options.desc = "Diagnostics (Picker)"; }
{ key = "<leader>ss"; mode = "n"; action = "<cmd>lua Snacks.picker.lsp_symbols()<CR>"; options.desc = "LSP Symbols"; }

# Flash
{ key = "s"; mode = [ "n" "x" "o" ]; action = "<cmd>lua require('flash').jump()<CR>"; options.desc = "Flash Jump"; }
{ key = "S"; mode = [ "n" "x" "o" ]; action = "<cmd>lua require('flash').treesitter()<CR>"; options.desc = "Flash Treesitter"; }
{ key = "r"; mode = "o"; action = "<cmd>lua require('flash').remote()<CR>"; options.desc = "Remote Flash"; }
{ key = "R"; mode = [ "o" "x" ]; action = "<cmd>lua require('flash').treesitter_search()<CR>"; options.desc = "Treesitter Search"; }
{ key = "<c-s>"; mode = "c"; action = "<cmd>lua require('flash').toggle()<CR>"; options.desc = "Toggle Flash Search"; }

# Gitsigns (expression mappings)
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
{ key = "<leader>hs"; mode = "n"; action = "<cmd>Gitsigns stage_hunk<CR>"; options.desc = "Stage Hunk"; }
{ key = "<leader>hr"; mode = "n"; action = "<cmd>Gitsigns reset_hunk<CR>"; options.desc = "Reset Hunk"; }
{ key = "<leader>hS"; mode = "n"; action = "<cmd>Gitsigns stage_buffer<CR>"; options.desc = "Stage Buffer"; }
{ key = "<leader>hu"; mode = "n"; action = "<cmd>Gitsigns undo_stage_hunk<CR>"; options.desc = "Undo Stage Hunk"; }
{ key = "<leader>hR"; mode = "n"; action = "<cmd>Gitsigns reset_buffer<CR>"; options.desc = "Reset Buffer"; }
{ key = "<leader>hp"; mode = "n"; action = "<cmd>Gitsigns preview_hunk<CR>"; options.desc = "Preview Hunk"; }
{ key = "<leader>hb"; mode = "n"; action = "<cmd>Gitsigns blame_line<CR>"; options.desc = "Blame Line"; }
{ key = "<leader>hd"; mode = "n"; action = "<cmd>Gitsigns diffthis<CR>"; options.desc = "Diff This"; }

# Snacks Picker
{ key = "<leader><space>"; mode = "n"; action = "<cmd>lua Snacks.picker.smart()<CR>"; options.desc = "Smart Picker"; }
{ key = "<leader>,"; mode = "n"; action = "<cmd>lua Snacks.picker.buffers()<CR>"; options.desc = "Buffers"; }
{ key = "<leader>/"; mode = "n"; action = "<cmd>lua Snacks.picker.grep()<CR>"; options.desc = "Grep"; }
{ key = "<leader>ff"; mode = "n"; action = "<cmd>lua Snacks.picker.files()<CR>"; options.desc = "Find Files"; }
{ key = "<leader>fr"; mode = "n"; action = "<cmd>lua Snacks.picker.recent()<CR>"; options.desc = "Recent Files"; }
{ key = "<leader>fb"; mode = "n"; action = "<cmd>lua Snacks.picker.buffers()<CR>"; options.desc = "Find Buffers"; }
{ key = "<leader>fg"; mode = "n"; action = "<cmd>lua Snacks.picker.grep()<CR>"; options.desc = "Grep"; }
{ key = "<leader>f?"; mode = "n"; action = "<cmd>lua Snacks.picker.help()<CR>"; options.desc = "Help"; }

# Snacks Explorer
{ key = "<leader>e"; mode = "n"; action = "<cmd>lua Snacks.explorer()<CR>"; options.desc = "Explorer"; }
{ key = "<leader>E"; mode = "n"; action = "<cmd>lua Snacks.explorer({ cwd = vim.fn.expand('%:p:h') })<CR>"; options.desc = "Explorer (Current Dir)"; }

# Snacks Git
{ key = "<leader>gB"; mode = [ "n" "v" ]; action = "<cmd>lua Snacks.gitbrowse()<CR>"; options.desc = "Git Browse"; }

# Snacks Utilities
{ key = "<leader>z"; mode = "n"; action = "<cmd>lua Snacks.zen()<CR>"; options.desc = "Zen Mode"; }
{ key = "<leader>Z"; mode = "n"; action = "<cmd>lua Snacks.zen.zoom()<CR>"; options.desc = "Zoom"; }
{ key = "<leader>."; mode = "n"; action = "<cmd>lua Snacks.scratch()<CR>"; options.desc = "Scratch Buffer"; }
{ key = "<leader>S"; mode = "n"; action = "<cmd>lua Snacks.scratch.select()<CR>"; options.desc = "Select Scratch"; }
{ key = "<leader>n"; mode = "n"; action = "<cmd>lua Snacks.notifier.show_history()<CR>"; options.desc = "Notification History"; }
{ key = "<leader>un"; mode = "n"; action = "<cmd>lua Snacks.notifier.hide()<CR>"; options.desc = "Dismiss Notifications"; }
{ key = "<c-/>"; mode = [ "n" "t" ]; action = "<cmd>lua Snacks.terminal()<CR>"; options.desc = "Terminal"; }
{ key = "<leader>bd"; mode = "n"; action = "<cmd>lua Snacks.bufdelete()<CR>"; options.desc = "Delete Buffer"; }
```

### extra.nix - Blink.cmp + Autopairs Integration

```lua
-- ========================================================================
-- BLINK.CMP INTEGRATION WITH NVIM-AUTOPAIRS
-- ========================================================================
local cmp = require('blink.cmp')
local npairs = require('nvim-autopairs')

vim.keymap.set('i', '<CR>', function()
  if cmp.is_visible() then
    return cmp.accept()
  else
    return npairs.autopairs_cr()
  end
end, { expr = true, replace_keycodes = false })
```

## Design Decisions Documented

1. **blink.cmp**: Using "default" preset with `<C-CR>` override (TODO: verify syntax)
2. **snacks.nvim**: Compact dashboard preset, zen module enabled, flash integration in picker
3. **Removed plugins**: dressing.nvim (use snacks.input), zen-mode.nvim (use snacks.zen)
4. **LSP Navigation**: Using snacks.picker for gd/gr/gI (TODO: evaluate vs native someday)
5. **Buffer delete**: Changed from `<leader>bx` to `<leader>bd` (TODO: audit other x->d changes)
6. **conform.nvim**: Verified lsp_fallback=true is correctly set

## Blockers Found

### sidekick.nvim Requires Copilot

**Error**: `sidekick requires either copilot-lua or copilot LSP to be enabled`

**Options**:

1. Enable copilot-lua plugin
2. Enable copilot LSP server
3. Temporarily disable sidekick until we configure copilot

**Recommendation**: Add copilot LSP server to lsp.servers configuration

## Next Steps

1. **BLOCKER**: Fix sidekick/copilot dependency
2. Complete plugins.nix edits (see above)
3. Add all keybindings to keymaps.nix
4. Update extra.nix with autopairs integration
5. Run `nix flake check` until it passes
6. Commit Group 1 changes
7. Proceed to Group 2 (medium priority plugins)
