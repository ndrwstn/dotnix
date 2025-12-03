# users/austin/nixvim/extra.nix
{ pkgs }: {
  extraPlugins = with pkgs.vimPlugins; [
    codewindow-nvim
    nvim-notify # Keep for snacks.notifier integration
    wrapping-nvim
    undotree
    # train-nvim removed - replaced by hardtime.nvim
    luasnip # Snippet engine for blink.cmp
  ];

  extraConfigLua = ''
    -- ========================================================================
    -- WRAPPING CONFIGURATION
    -- ========================================================================
    require('wrapping').setup {
      softener = {
        tex = true;
        latex = true;
      },
    }
    
    -- ========================================================================
    -- CODEWINDOW (MINIMAP) CONFIGURATION
    -- ========================================================================
    require('codewindow').setup {}
    -- TODO: Add keybinding to toggle minimap in keymaps.nix
    
    -- ========================================================================
    -- NOTIFY INTEGRATION WITH SNACKS
    -- ========================================================================
    vim.notify = require("notify")

    -- ========================================================================
    -- UNDOTREE CONFIGURATION
    -- ========================================================================
    vim.g.undotree_WindowLayout = 2
    vim.g.undotree_ShortIndicators = 1
    vim.g.undotree_SetFocusWhenToggle = 1

    -- ========================================================================
    -- BLINK.CMP ACCEPT WRAPPER WITH AUTOPAIRS AND LUASNIP INTEGRATION
    -- ========================================================================
    -- Wrapper function to handle blink accept, autopairs, and luasnip expansion
    local function blink_accept_with_autopairs_and_luasnip()
      local ok, blink = pcall(require, '' blink.cmp'')
  if not ok or not blink or type(blink.accept) ~= ''function'' then
  -- Fallback to normal Enter behavior
  return vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(''<CR>'', true, false, true), ''n'', true)
  end

  -- Prepare autopairs handler (if available)
  local ok_ap, cmp_ap = pcall(require, ''nvim-autopairs.completion.cmp'')
  local autopairs_handler = nil
  if ok_ap and cmp_ap and type(cmp_ap.on_confirm_done) == ''function'' then
  local ok_h, handler = pcall(cmp_ap.on_confirm_done, {}) -- Returns function(evt)
  if ok_h and type(handler) == ''function'' then autopairs_handler = handler end
  end

  -- Luasnip (if present)
  local ok_ls, luasnip = pcall(require, ''luasnip'')

  -- Try to grab selected entry BEFORE accept (best-effort)
  local selected_entry
  for _, name in ipairs({ ''get_selected'', ''get_selected_entry'', ''get_selected_item'', ''selected'' }) do
  if blink[name] and type(blink[name]) == ''function'' then
  pcall(function() selected_entry = blink[name]() end)
  if selected_entry then break end
  end
  end

  -- Perform accept
  pcall(blink.accept)

  -- Schedule followups so buffer edits / LSP textEdits finish
  vim.schedule(function()
  -- Re-check selected entry if missing
  if not selected_entry then
  for _, name in ipairs({ ''get_selected'', ''get_selected_entry'', ''get_selected_item'', ''selected'' }) do
  if blink[name] and type(blink[name]) == ''function'' then
  pcall(function() selected_entry = blink[name]() end)
  if selected_entry then break end
  end
  end
  end

  -- Derive a completion_item (LSP shape) if possible
  local completion_item
  if selected_entry then
  if type(selected_entry.get_completion_item) == ''function'' then
  pcall(function() completion_item = selected_entry:get_completion_item() end)
  elseif selected_entry.item then
  completion_item = selected_entry.item
  elseif selected_entry.completion_item then
  completion_item = selected_entry.completion_item
  end
  end

  -- Luasnip: expand if snippet-like
  if ok_ls and completion_item then
  local body = (completion_item.textEdit and completion_item.textEdit.newText)
  or completion_item.insertText
  or completion_item.label
  local is_snippet = completion_item.insertTextFormat == 2
  or (body and tostring(body):match("%%${")) -- Crude snippet marker detection
          if is_snippet and body then
            pcall(function() luasnip.lsp_expand(body) end)
          end
        end

        -- Autopairs: call the handler with a cmp-style event (or shim)
        if autopairs_handler then
          local event = nil
          if selected_entry and type(selected_entry.get_completion_item) == ''function'' then
            event = { entry = selected_entry }
          elseif completion_item then
            event = { entry = { get_completion_item = function() return completion_item end } }
          else
            event = {}
          end
          pcall(function() autopairs_handler(event) end)
        end
      end)
    end

    -- Map <CR> to the wrapper in insert mode
    vim.keymap.set(''i'', ''<CR>'', blink_accept_with_autopairs_and_luasnip, { expr = false, silent = true })

    -- ========================================================================
    -- SIDEKICK.NVIM - ENABLE COPILOT LSP
    -- ========================================================================
    -- Required for NES (Next Edit Suggestions) feature
    -- Note: Requires active GitHub Copilot subscription
    -- Sign in with: :LspCopilotSignIn
    -- vim.lsp.enable("copilot")
  '';
}





