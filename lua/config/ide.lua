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

--- Check if IDE features (LSP + Autocomplete) are currently enabled for the buffer
---@param bufnr integer?
---@return boolean
function M.is_enabled(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local ft = vim.bo[bufnr].filetype

  -- 1. Java is ALWAYS permanently disabled (DSA mode)
  if ft == "java" then
    return false
  end

  -- 2. Buffer-local override
  local b_val = vim.b[bufnr].ide_enabled
  if b_val ~= nil then
    return b_val == true
  end

  -- 3. Global override
  if vim.g.ide_enabled ~= nil then
    return vim.g.ide_enabled == true
  end

  -- 4. Default by filetype
  return M.default_filetypes[ft] == true
end

--- Toggle IDE features (LSP & Autocomplete) for the current buffer
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
  vim.b[bufnr].ide_enabled = new_state

  local label = (ft and ft ~= "") and ft:upper() or "current buffer"

  if not new_state then
    -- Turn OFF: detach active LSP clients and close any active completion menu
    local clients = vim.lsp.get_clients({ bufnr = bufnr })
    for _, client in ipairs(clients) do
      pcall(vim.lsp.buf_detach_client, bufnr, client.id)
    end

    local ok_cmp, cmp = pcall(require, "cmp")
    if ok_cmp and cmp.visible() then
      pcall(cmp.abort)
    end

    vim.notify(string.format("IDE (LSP & Autocomplete): OFF for %s", label), vim.log.levels.WARN, { title = "IDE Toggle" })
  else
    -- Turn ON: start/attach appropriate LSP servers
    local servers = M.ft_servers[ft] or {}
    for _, s in ipairs(servers) do
      if vim.lsp.config and vim.lsp.config[s] then
        pcall(vim.lsp.start, vim.lsp.config[s], { bufnr = bufnr })
      end
    end

    vim.notify(string.format("IDE (LSP & Autocomplete): ON for %s", label), vim.log.levels.INFO, { title = "IDE Toggle" })
  end
end

--- Toggle IDE features globally for all buffers
function M.toggle_global()
  local current = vim.g.ide_enabled
  if current == nil then
    current = true
  end
  local new_state = not current
  vim.g.ide_enabled = new_state

  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) and vim.bo[bufnr].filetype ~= "java" then
      vim.b[bufnr].ide_enabled = new_state
      if not new_state then
        local clients = vim.lsp.get_clients({ bufnr = bufnr })
        for _, client in ipairs(clients) do
          pcall(vim.lsp.buf_detach_client, bufnr, client.id)
        end
      else
        local ft = vim.bo[bufnr].filetype
        local servers = M.ft_servers[ft] or {}
        for _, s in ipairs(servers) do
          if vim.lsp.config and vim.lsp.config[s] then
            pcall(vim.lsp.start, vim.lsp.config[s], { bufnr = bufnr })
          end
        end
      end
    end
  end

  local ok_cmp, cmp = pcall(require, "cmp")
  if ok_cmp and not new_state and cmp.visible() then
    pcall(cmp.abort)
  end

  local state_str = new_state and "ENABLED" or "DISABLED"
  local level = new_state and vim.log.levels.INFO or vim.log.levels.WARN
  vim.notify(string.format("IDE (LSP & Autocomplete): Globally %s (Java remains disabled)", state_str), level, { title = "IDE Toggle" })
end

-- Setup user commands and keymaps
function M.setup()
  vim.api.nvim_create_user_command("IdeToggle", function(opts)
    if opts.args == "global" then
      M.toggle_global()
    else
      M.toggle()
    end
  end, { nargs = "?", desc = "Toggle LSP & Autocomplete for current buffer (or 'global')" })

  vim.api.nvim_create_user_command("LspToggle", function()
    M.toggle()
  end, { desc = "Toggle LSP & Autocomplete for current buffer" })

  vim.api.nvim_create_user_command("CmpToggle", function()
    M.toggle()
  end, { desc = "Toggle LSP & Autocomplete for current buffer" })

  -- Keybindings: <leader>cl for buffer toggle, <leader>cL for global toggle
  vim.keymap.set("n", "<leader>cl", M.toggle, { noremap = true, silent = true, desc = "[C]ode Toggle [L]SP & Autocomplete" })
  vim.keymap.set("n", "<leader>cL", M.toggle_global, { noremap = true, silent = true, desc = "[C]ode Toggle [L]SP Globally" })
end

return M
