local M = {
  win = nil,
  buf = nil,
  auto_reload_timer = nil,
}

-- Automatically reload files when they change on disk
vim.opt.autoread = true
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold" }, {
  pattern = "*",
  callback = function()
    if vim.fn.mode() ~= "c" then
      vim.cmd("checktime")
    end
  end,
})

-- Keep Antigravity pinned to the far right whenever new buffers/splits are opened
vim.api.nvim_create_autocmd("BufWinEnter", {
  pattern = "*",
  callback = function(args)
    if M.win and vim.api.nvim_win_is_valid(M.win) then
      local cur_win = vim.api.nvim_get_current_win()
      if cur_win ~= M.win and vim.bo[args.buf].filetype ~= "NvimTree" and vim.bo[args.buf].buftype == "" then
        vim.schedule(function()
          if M.win and vim.api.nvim_win_is_valid(M.win) then
            vim.api.nvim_win_call(M.win, function()
              vim.cmd("wincmd L")
              vim.cmd("vertical resize 52")
            end)
          end
        end)
      end
    end
  end,
})

-- Allow :wqa to work smoothly without being blocked by the AGY background job
vim.api.nvim_create_autocmd("QuitPre", {
  pattern = "*",
  callback = function()
    if M.buf and vim.api.nvim_buf_is_valid(M.buf) then
      pcall(vim.api.nvim_buf_delete, M.buf, { force = true })
    end
  end,
})

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
  if buf_path ~= "" then
    if vim.fn.isdirectory(buf_path) == 1 then
      return buf_path
    else
      return vim.fn.fnamemodify(buf_path, ":h")
    end
  end

  return vim.fn.getcwd()
end

function M.launch_antigravity_side()
  local folder = get_selected_folder()
  if not folder then
    vim.notify("Antigravity: Could not determine folder.", vim.log.levels.WARN, { title = "Antigravity" })
    return
  end

  -- If Antigravity is already open, focus it
  if M.win and vim.api.nvim_win_is_valid(M.win) then
    vim.api.nvim_set_current_win(M.win)
    vim.cmd("startinsert")
    return
  end

  -- Create a clean scratch buffer for the terminal
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].buflisted = false
  vim.bo[buf].filetype = "antigravity"

  -- Open a vertical split on the far right
  vim.cmd("botright 52vsplit")
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, buf)

  -- Terminal UI tweaks & lock width
  vim.wo[win].winfixwidth = true
  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  vim.wo[win].signcolumn = "no"

  M.win = win
  M.buf = buf

  -- Determine agy binary path
  local agy_bin = vim.fn.exepath("agy")
  if agy_bin == "" then
    agy_bin = vim.fn.expand("~/.local/bin/agy")
  end

  -- Start a background timer to check for file changes 2 times a second while AGY is running
  if not M.auto_reload_timer then
    M.auto_reload_timer = vim.uv.new_timer()
    M.auto_reload_timer:start(0, 500, vim.schedule_wrap(function()
      if vim.fn.mode() ~= "c" then
        vim.cmd("checktime")
      end
    end))
  end

  -- Spawn agy inside the target directory
  vim.fn.termopen({ agy_bin }, {
    cwd = folder,
    on_exit = function()
      if vim.api.nvim_win_is_valid(win) then
        pcall(vim.api.nvim_win_close, win, true)
      end
      if M.auto_reload_timer then
        M.auto_reload_timer:stop()
        M.auto_reload_timer:close()
        M.auto_reload_timer = nil
      end
      M.win = nil
      M.buf = nil
    end,
  })

  vim.cmd("startinsert")
end

-- Create user command
vim.api.nvim_create_user_command("AntigravitySide", function()
  M.launch_antigravity_side()
end, { desc = "Open Antigravity CLI in a side panel for the selected folder" })

-- Keymap: <leader>ag
vim.keymap.set("n", "<leader>ag", function()
  M.launch_antigravity_side()
end, { noremap = true, silent = true, desc = "Open [A]nti[G]ravity in selected folder" })

return M
