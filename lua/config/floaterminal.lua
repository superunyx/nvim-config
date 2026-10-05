local M = {}
local state = { win = -1, buf = -1 }

local function create_floating_window(opts, existing_buf)
  opts = opts or {}
  local width = opts.width or math.floor(vim.o.columns * 0.8)
  local height = opts.height or math.floor(vim.o.lines * 0.8)

  local col = math.floor((vim.o.columns - width) / 2)
  local row = math.floor((vim.o.lines - height) / 2)

  local buf = existing_buf
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    buf = vim.api.nvim_create_buf(false, true)
  end

  local win_config = {
    relative = "editor",
    width = width,
    height = height,
    col = col,
    row = row,
    style = "minimal",
    border = "rounded",
  }

  local win = vim.api.nvim_open_win(buf, true, win_config)
  return { buf = buf, win = win }
end

local function get_selected_folder()
  -- Check if cursor is in nvim-tree
  if vim.bo.filetype == "NvimTree" then
    local ok, api = pcall(require, "nvim-tree.api")
    if ok then
      local node = api.tree.get_node_under_cursor()
      if node and node.absolute_path then
        if node.type == "directory" or (node.fs_stat and node.fs_stat.type == "directory") or vim.fn.isdirectory(node.absolute_path) == 1 then
          return node.absolute_path
        else
          return vim.fn.fnamemodify(node.absolute_path, ":h")
        end
      end
    end
    return nil
  end

  -- Check if current buffer is a valid path
  local buf_path = vim.fn.expand("%:p")
  if buf_path ~= "" and not buf_path:match("^%a+://") then
    if vim.fn.isdirectory(buf_path) == 1 then
      return buf_path
    else
      return vim.fn.fnamemodify(buf_path, ":h")
    end
  end

  return vim.fn.getcwd()
end

local function toggle_terminal(cmd, target_dir)
  if vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_win_hide(state.win)
    state.win = -1
    return
  end

  local folder = target_dir or get_selected_folder() or vim.fn.getcwd()

  pcall(function()
    require("config.venv").auto_activate(folder)
  end)

  -- Reopen existing interactive terminal session if available and no specific command
  if not cmd and vim.api.nvim_buf_is_valid(state.buf) then
    local floating = create_floating_window({}, state.buf)
    state.win = floating.win
    vim.cmd("startinsert")
    return
  end

  local floating = create_floating_window()
  state.win = floating.win
  if not cmd then
    state.buf = floating.buf
  end

  -- Buffer-local keymaps: double escape closes floaterminal
  local close_opts = { buffer = floating.buf, noremap = true, silent = true, desc = "Close Floaterminal" }
  vim.keymap.set({ "n", "t" }, "<esc><esc>", function()
    toggle_terminal()
  end, close_opts)
  vim.keymap.set("n", "q", function()
    toggle_terminal()
  end, close_opts)

  -- Open terminal and run command if provided
  local shell_cmd = cmd or vim.o.shell
  vim.fn.termopen(shell_cmd, {
    cwd = folder,
    on_exit = function()
      if not cmd then
        state.buf = -1
      end
      if vim.api.nvim_win_is_valid(state.win) and vim.api.nvim_win_get_buf(state.win) == floating.buf then
        vim.api.nvim_win_hide(state.win)
        state.win = -1
      end
    end,
  })

  vim.cmd("startinsert")
end

function M.is_open()
  return vim.api.nvim_win_is_valid(state.win)
end

function M.hide()
  if vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_win_hide(state.win)
    state.win = -1
  end
end

function M.show(cmd, target_dir)
  if not vim.api.nvim_win_is_valid(state.win) then
    toggle_terminal(cmd, target_dir)
  end
end

function M.toggle(cmd, target_dir)
  toggle_terminal(cmd, target_dir)
end

-- General floating terminal
vim.api.nvim_create_user_command("Floaterminal", function(opts)
  local cmd = (opts and opts.args ~= "") and opts.args or nil
  toggle_terminal(cmd)
end, { nargs = "*", desc = "Toggle floating terminal" })

-- Java compile & run (on current file)
vim.api.nvim_create_user_command("JavaRun", function()
  local file = vim.fn.expand("%:p")   -- full path
  local classname = vim.fn.expand("%:t:r") -- filename without extension
  local dir = vim.fn.expand("%:p:h")  -- directory
  toggle_terminal(string.format("javac %s && java %s", vim.fn.fnameescape(file), vim.fn.fnameescape(classname)), dir)
end, {})

-- Python run (on current file)
vim.api.nvim_create_user_command("PythonRun", function()
  local file = vim.fn.expand("%:p")
  local dir = vim.fn.expand("%:p:h")
  local venv = require("config.venv").auto_activate(dir)
  local python_bin = (venv and (venv .. "/bin/python")) or "python3"
  toggle_terminal(string.format("%s %s", vim.fn.fnameescape(python_bin), vim.fn.fnameescape(file)), dir)
end, {})

-- HTML / CSS live server run (serves folder and opens current file in browser)
vim.api.nvim_create_user_command("HtmlRun", function()
  local ok = pcall(vim.cmd, "LiveServerStart")
  if not ok then
    local file = vim.fn.expand("%:t")
    local dir = vim.fn.expand("%:p:h")
    if vim.fn.executable("live-server") == 1 then
      toggle_terminal(string.format("live-server --open=%s", vim.fn.fnameescape(file)), dir)
    else
      local full = vim.fn.expand("%:p")
      vim.ui.open(full)
    end
  end
end, {})

-- JavaScript run (node)
vim.api.nvim_create_user_command("JsRun", function()
  local file = vim.fn.expand("%:p")
  local dir = vim.fn.expand("%:p:h")
  toggle_terminal(string.format("node %s", vim.fn.fnameescape(file)), dir)
end, {})

-- TypeScript run
vim.api.nvim_create_user_command("TsRun", function()
  local file = vim.fn.expand("%:p")
  local dir = vim.fn.expand("%:p:h")
  toggle_terminal(string.format("npx ts-node %s", vim.fn.fnameescape(file)), dir)
end, {})

-- Shell / Bash run
vim.api.nvim_create_user_command("BashRun", function()
  local file = vim.fn.expand("%:p")
  local dir = vim.fn.expand("%:p:h")
  toggle_terminal(string.format("bash %s", vim.fn.fnameescape(file)), dir)
end, {})

-- Filetype-aware smart runner (runs Java, Python, JS, TS, HTML, CSS, Bash)
vim.api.nvim_create_user_command("CodeRun", function()
  local ft = vim.bo.filetype
  if ft == "java" then
    vim.cmd("JavaRun")
  elseif ft == "python" then
    vim.cmd("PythonRun")
  elseif ft == "javascript" or ft == "javascriptreact" then
    vim.cmd("JsRun")
  elseif ft == "typescript" or ft == "typescriptreact" then
    vim.cmd("TsRun")
  elseif ft == "html" or ft == "htmldjango" or ft == "css" or ft == "scss" or ft == "less" then
    vim.cmd("HtmlRun")
  elseif ft == "sh" or ft == "bash" then
    vim.cmd("BashRun")
  else
    vim.notify("No run command configured for filetype: " .. ft, vim.log.levels.WARN)
  end
end, {})

-- Keymaps
vim.keymap.set("n", "<leader>t", ":Floaterminal<CR>", { noremap = true, silent = true, desc = "Toggle [T]erminal" })
vim.keymap.set("n", "<leader>rj", ":JavaRun<CR>", { noremap = true, silent = true, desc = "[R]un [J]ava" })
vim.keymap.set("n", "<leader>jr", ":JavaRun<CR>", { noremap = true, silent = true, desc = "[J]ava [R]un" })
vim.keymap.set("n", "<leader>rp", ":PythonRun<CR>", { noremap = true, silent = true, desc = "[R]un [P]ython" })
vim.keymap.set("n", "<leader>pr", ":PythonRun<CR>", { noremap = true, silent = true, desc = "[P]ython [R]un" })
vim.keymap.set("n", "<leader>rh", ":HtmlRun<CR>", { noremap = true, silent = true, desc = "[R]un [H]TML / Web" })
vim.keymap.set("n", "<leader>rn", ":JsRun<CR>", { noremap = true, silent = true, desc = "[R]un [N]ode / JS" })
vim.keymap.set("n", "<leader>rr", ":CodeRun<CR>", { noremap = true, silent = true, desc = "[R]un current file (Smart)" })

return M
