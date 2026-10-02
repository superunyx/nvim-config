local state = { win = -1 }

local function create_floating_window(opts)
  opts = opts or {}
  local width = opts.width or math.floor(vim.o.columns * 0.8)
  local height = opts.height or math.floor(vim.o.lines * 0.8)

  local col = math.floor((vim.o.columns - width) / 2)
  local row = math.floor((vim.o.lines - height) / 2)

  -- New scratch buffer every time
  local buf = vim.api.nvim_create_buf(false, true)

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
  if not vim.api.nvim_win_is_valid(state.win) then
    local folder = target_dir or get_selected_folder() or vim.fn.getcwd()

    pcall(function()
      require("config.venv").auto_activate(folder)
    end)

    local floating = create_floating_window()
    state.win = floating.win

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
    vim.fn.termopen(shell_cmd, { cwd = folder })

    vim.cmd("startinsert")
  else
    vim.api.nvim_win_hide(state.win)
    state.win = -1
  end
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

-- Filetype-aware smart runner (runs Java when in .java, Python when in .py)
vim.api.nvim_create_user_command("CodeRun", function()
  local ft = vim.bo.filetype
  if ft == "java" then
    vim.cmd("JavaRun")
  elseif ft == "python" then
    vim.cmd("PythonRun")
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
vim.keymap.set("n", "<leader>rr", ":CodeRun<CR>", { noremap = true, silent = true, desc = "[R]un current file (Smart)" })

