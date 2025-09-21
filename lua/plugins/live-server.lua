return {
  "barrett-ruth/live-server.nvim",
  build = "npm install -g live-server", -- or "pnpm add -g live-server"
  cmd = { "LiveServerStart", "LiveServerStop" },
  keys = {
    { "<leader>ls", "<cmd>LiveServerStart<cr>", desc = "Start Live Server" },
    { "<leader>lx", "<cmd>LiveServerStop<cr>",  desc = "Stop Live Server"  },
  },
  opts = {
    port = 5500, -- optional, default is 5500
    browser_command = nil, -- e.g. "firefox"
    quiet = false, -- don't show server logs
  }
}
