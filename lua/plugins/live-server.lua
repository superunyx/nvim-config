return {
  "barrett-ruth/live-server.nvim",
  build = "npm install -g live-server", -- or "pnpm add -g live-server"
  cmd = { "LiveServerStart", "LiveServerStop", "LiveServerToggle" },
  keys = {
    { "<leader>ls", desc = "Start / Open Current File in Live Server" },
    { "<leader>lx", desc = "Stop Live Server" },
  },
  init = function()
    -- Configure live-server.nvim to not auto-open the generic root URL (/)
    -- so our smart opener can open the exact file being worked on.
    vim.g.live_server = {
      port = 5500,
      browser = false,
      quiet = false,
    }
  end,
  config = function()
    local live_server = require("live-server")

    -- Cleanly stop any existing live-server instances across all directories
    local function stop_all_instances()
      local ok, ls = pcall(require, "live-server")
      if not ok then
        return
      end
      local server_mod, instances_tbl
      local i = 1
      while true do
        local name, val = debug.getupvalue(ls.stop, i)
        if not name then
          break
        end
        if name == "instances" then
          instances_tbl = val
        end
        if name == "server" then
          server_mod = val
        end
        i = i + 1
      end

      if instances_tbl and server_mod then
        for dir, inst in pairs(instances_tbl) do
          pcall(server_mod.stop, inst)
          instances_tbl[dir] = nil
          vim.api.nvim_exec_autocmds("User", {
            pattern = "LiveServerStopped",
            data = { port = inst.port, root = inst.root_real },
          })
        end
      end
    end

    local function get_project_root()
      local buf_path = vim.api.nvim_buf_get_name(0)
      if buf_path == "" then
        return vim.fn.getcwd()
      end
      local root = vim.fs.root(0, { ".git", "package.json", "index.html" })
      if root and root ~= "" then
        return root
      end
      return vim.fs.dirname(buf_path) or vim.fn.getcwd()
    end

    local function open_file_in_live_server()
      -- Automatically close any previously running live-server instance
      stop_all_instances()

      local root = get_project_root()
      local port = (vim.g.live_server and vim.g.live_server.port) or 5500
      local buf_path = vim.api.nvim_buf_get_name(0)

      -- Start server for the current project root
      live_server.start(root)

      -- Compute URL for the exact file currently being edited
      local url = string.format("http://127.0.0.1:%d/", port)
      if buf_path ~= "" then
        local real_buf = vim.uv.fs_realpath(buf_path) or buf_path
        local real_root = vim.uv.fs_realpath(root) or root

        if real_root and real_buf:sub(1, #real_root) == real_root then
          local rel = real_buf:sub(#real_root + 1):gsub("^/", "")
          if rel ~= "" then
            url = string.format("http://127.0.0.1:%d/%s", port, rel)
          end
        else
          local fname = vim.fs.basename(real_buf)
          if fname ~= "" then
            url = string.format("http://127.0.0.1:%d/%s", port, fname)
          end
        end
      end

      -- Small delay to ensure server socket is listening
      vim.defer_fn(function()
        vim.ui.open(url)
        local display_name = (buf_path ~= "" and vim.fs.basename(buf_path)) or "Live Server"
        vim.notify(string.format("Live Server started: %s", url), vim.log.levels.INFO, { title = display_name })
      end, 200)
    end

    -- Replace LiveServerStart user command so it stops previous and opens current file
    vim.api.nvim_create_user_command("LiveServerStart", function()
      open_file_in_live_server()
    end, { desc = "Start live-server (auto-closing previous) and open current file in browser" })

    -- Replace LiveServerStop user command so it cleans up all instances
    vim.api.nvim_create_user_command("LiveServerStop", function()
      stop_all_instances()
      vim.notify("Live Server stopped", vim.log.levels.WARN, { title = "Live Server" })
    end, { desc = "Stop all running live-server instances" })

    -- Map <leader>ls to smart open (closes previous instance first)
    vim.keymap.set("n", "<leader>ls", open_file_in_live_server, {
      noremap = true,
      silent = true,
      desc = "Start / Open Current File in Live Server (Auto-close previous)",
    })

    -- Map <leader>lx to stop all
    vim.keymap.set("n", "<leader>lx", function()
      stop_all_instances()
      vim.notify("Live Server stopped", vim.log.levels.WARN, { title = "Live Server" })
    end, {
      noremap = true,
      silent = true,
      desc = "Stop Live Server",
    })
  end,
}
