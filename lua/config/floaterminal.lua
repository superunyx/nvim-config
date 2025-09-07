
vim.keymap.set("t", "<esc><esc>", "<c-\\><c-n>", { noremap = true })

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

local function toggle_terminal(cmd)
  if not vim.api.nvim_win_is_valid(state.win) then
    local floating = create_floating_window()
    state.win = floating.win

    -- Open terminal and run command if provided
    if cmd then
      vim.fn.termopen(cmd)
    else
      vim.cmd("terminal")
    end

    vim.cmd("startinsert")
  else
    vim.api.nvim_win_hide(state.win)
    state.win = -1
  end
end

-- General floating terminal
vim.api.nvim_create_user_command("Floaterminal", function()
  toggle_terminal()
end, {})

-- Java compile & run (on current file)
vim.api.nvim_create_user_command("JavaRun", function()
  local file = vim.fn.expand("%:p")   -- full path
  local classname = vim.fn.expand("%:t:r") -- filename without extension
  local dir = vim.fn.expand("%:p:h")  -- directory
  toggle_terminal(string.format("cd %s && javac %s && java %s", dir, file, classname))
end, {})

-- Optional keymaps
vim.keymap.set("n", "<leader>t", ":Floaterminal<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>rj", ":JavaRun<CR>", { noremap = true, silent = true })

