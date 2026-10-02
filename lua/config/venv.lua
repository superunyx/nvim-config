local M = {}

local current_venv = nil

---Search upward from `start_dir` for a Python virtual environment directory (.venv, venv, .env, env)
---@param start_dir? string
---@return string|nil
function M.find_venv(start_dir)
  if not start_dir or start_dir == "" or start_dir:match("^%a+://") then
    local buf_name = vim.api.nvim_buf_get_name(0)
    if buf_name and buf_name ~= "" and not buf_name:match("^%a+://") then
      start_dir = vim.fs.dirname(buf_name)
    else
      start_dir = vim.fn.getcwd()
    end
  elseif vim.fn.isdirectory(start_dir) == 0 and vim.fn.filereadable(start_dir) == 1 then
    start_dir = vim.fs.dirname(start_dir)
  end

  local candidates = { ".venv", "venv", ".env", "env" }
  local matches = vim.fs.find(candidates, {
    upward = true,
    path = start_dir,
    type = "directory",
  })

  for _, match in ipairs(matches) do
    if vim.fn.executable(match .. "/bin/python") == 1 or vim.fn.executable(match .. "/bin/python3") == 1 then
      return vim.fs.normalize(match)
    end
  end

  return nil
end

---Activate a virtual environment by prepending its bin to PATH and setting VIRTUAL_ENV
---@param venv_path string
---@param opts? { silent?: boolean }
---@return boolean
function M.activate_venv(venv_path, opts)
  opts = opts or {}
  if not venv_path or venv_path == "" then
    return false
  end

  venv_path = vim.fs.normalize(venv_path)
  if venv_path == current_venv then
    return true
  end

  local bin_path = venv_path .. "/bin"
  if vim.fn.isdirectory(bin_path) == 0 then
    return false
  end

  -- Clean previously managed venv from PATH
  local paths = vim.split(vim.env.PATH or "", ":", { trimempty = true })
  local filtered = {}
  for _, p in ipairs(paths) do
    if p ~= bin_path and (not current_venv or p ~= (current_venv .. "/bin")) then
      table.insert(filtered, p)
    end
  end
  table.insert(filtered, 1, bin_path)

  vim.env.PATH = table.concat(filtered, ":")
  vim.env.VIRTUAL_ENV = venv_path
  vim.env.VIRTUAL_ENV_PROMPT = "(" .. vim.fs.basename(venv_path) .. ") "
  current_venv = venv_path

  if not opts.silent then
    vim.notify("Activated virtualenv: " .. venv_path, vim.log.levels.INFO, { title = "Python Venv" })
  end

  return true
end

---Automatically find and activate a virtual environment
---@param start_dir? string
---@param opts? { silent?: boolean }
---@return string|nil
function M.auto_activate(start_dir, opts)
  local v = M.find_venv(start_dir)
  if v then
    M.activate_venv(v, opts)
    return v
  end
  return nil
end

---Get current active virtual environment path
---@return string|nil
function M.get_current_venv()
  return current_venv or vim.env.VIRTUAL_ENV
end

---Setup automatic venv detection on file opening and directory change
function M.setup()
  local group = vim.api.nvim_create_augroup("AutoVenvActivation", { clear = true })

  -- Auto-activate when opening Python files
  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = "python",
    callback = function(args)
      local dir = vim.fs.dirname(vim.api.nvim_buf_get_name(args.buf))
      M.auto_activate(dir, { silent = false })
    end,
  })

  -- Auto-activate when switching directories
  vim.api.nvim_create_autocmd("DirChanged", {
    group = group,
    callback = function()
      M.auto_activate(vim.fn.getcwd(), { silent = false })
    end,
  })

  -- Initial check on startup
  vim.schedule(function()
    M.auto_activate(nil, { silent = true })
  end)

  -- User commands
  vim.api.nvim_create_user_command("VenvStatus", function()
    local venv = M.get_current_venv()
    if venv then
      vim.notify("Current active venv: " .. venv, vim.log.levels.INFO, { title = "Python Venv" })
    else
      vim.notify("No virtualenv currently active", vim.log.levels.WARN, { title = "Python Venv" })
    end
  end, { desc = "Show active Python virtual environment" })

  vim.api.nvim_create_user_command("VenvActivate", function(opts)
    local target = opts.args ~= "" and opts.args or nil
    local venv = target and M.activate_venv(target, { silent = false }) or M.auto_activate(nil, { silent = false })
    if not venv then
      vim.notify("No virtualenv found to activate", vim.log.levels.WARN, { title = "Python Venv" })
    end
  end, { nargs = "?", complete = "dir", desc = "Activate Python virtual environment" })
end

return M
