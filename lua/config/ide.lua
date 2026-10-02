local M = {}

-- Filetypes where IDE features (LSP + Autocomplete) are active by default
M.default_filetypes = {
  python = true,
  html = true,
  htmldjango = true,
  css = true,
  scss = true,
  less = true,
  javascript = true,
  typescript = true,
  javascriptreact = true,
  typescriptreact = true,
  json = true,
  jsonc = true,
}

-- All configured language servers
M.all_servers = {
  "pyright",
  "ruff",
  "html",
  "cssls",
  "ts_ls",
  "emmet_language_server",
}

-- Mapping of filetypes to LSP server names
M.ft_servers = {
  python = { "pyright", "ruff" },
  html = { "html", "emmet_language_server" },
  htmldjango = { "html", "emmet_language_server" },
  css = { "cssls", "emmet_language_server" },
  scss = { "cssls", "emmet_language_server" },
  less = { "cssls", "emmet_language_server" },
  javascript = { "ts_ls" },
  typescript = { "ts_ls" },
  javascriptreact = { "ts_ls", "emmet_language_server" },
  typescriptreact = { "ts_ls", "emmet_language_server" },
}

--- Check if the given buffer is a Java buffer (always locked disabled for DSA)
---@param bufnr integer?
---@return boolean
function M.is_java(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  return vim.bo[bufnr].filetype == "java"
end

--- Check if IDE features (LSP + Autocomplete) are currently enabled
--- Persists session-wide across all files opened or created in this session.
---@param bufnr integer?
---@return boolean
function M.is_enabled(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local ft = vim.bo[bufnr].filetype

  -- 1. Java is ALWAYS permanently disabled (DSA mode)
  if ft == "java" then
    return false
  end

  -- 2. Buffer-local override (if explicitly set for a specific buffer)
  local b_val = vim.b[bufnr].ide_enabled
  if b_val ~= nil then
    return b_val == true
  end

  -- 3. Session-wide state (persists across all files in this session)
  if vim.g.ide_enabled ~= nil then
    return vim.g.ide_enabled == true
  end

  -- 4. Default for new sessions by filetype
  return M.default_filetypes[ft] == true
end

--- Toggle IDE features (LSP & Autocomplete) for the session (persists for all new files)
---@param bufnr integer?
function M.toggle(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local ft = vim.bo[bufnr].filetype

  if ft == "java" then
    vim.notify("Java DSA Mode: LSP and Autocomplete are permanently disabled.", vim.log.levels.WARN, { title = "IDE Toggle" })
    return
  end

  -- Ensure lazy plugins are loaded
  pcall(function()
    require("lazy").load({ plugins = { "nvim-lspconfig", "nvim-cmp", "LuaSnip" } })
  end)

  local current = M.is_enabled(bufnr)
  local new_state = not current

  -- Set session-wide state so every new file created or opened keeps this setting
  vim.g.ide_enabled = new_state

  -- Also update vim.lsp.enable for all servers
  pcall(vim.lsp.enable, M.all_servers, new_state)

  -- Apply to all currently loaded buffers
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(b) and vim.bo[b].filetype ~= "java" then
      vim.b[b].ide_enabled = new_state
      if not new_state then
        local clients = vim.lsp.get_clients({ bufnr = b })
        for _, client in ipairs(clients) do
          pcall(vim.lsp.buf_detach_client, b, client.id)
        end
      else
        local b_ft = vim.bo[b].filetype
        local servers = M.ft_servers[b_ft] or {}
        for _, s in ipairs(servers) do
          if vim.lsp.config and vim.lsp.config[s] then
            pcall(vim.lsp.start, vim.lsp.config[s], { bufnr = b })
          end
        end
      end
    end
  end

  local ok_cmp, cmp = pcall(require, "cmp")
  if ok_cmp and not new_state and cmp.visible() then
    pcall(cmp.abort)
  end

  local state_str = new_state and "ON" or "OFF"
  local level = new_state and vim.log.levels.INFO or vim.log.levels.WARN
  vim.notify(string.format("IDE (LSP & Autocomplete): %s for session (persists for new files)", state_str), level, { title = "IDE Toggle" })
end

-- Setup user commands and keymaps
function M.setup()
  vim.api.nvim_create_user_command("IdeToggle", function()
    M.toggle()
  end, { desc = "Toggle LSP & Autocomplete for session (persists for new files)" })

  vim.api.nvim_create_user_command("LspToggle", function()
    M.toggle()
  end, { desc = "Toggle LSP & Autocomplete for session (persists for new files)" })

  vim.api.nvim_create_user_command("CmpToggle", function()
    M.toggle()
  end, { desc = "Toggle LSP & Autocomplete for session (persists for new files)" })

  -- Keybinding: <leader>cl toggles for the session
  vim.keymap.set("n", "<leader>cl", M.toggle, { noremap = true, silent = true, desc = "[C]ode Toggle [L]SP & Autocomplete (Session)" })
end

return M
