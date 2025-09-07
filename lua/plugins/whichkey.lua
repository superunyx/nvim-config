
return {
  "folke/which-key.nvim",
  event = "VimEnter",
  config = function()
    local which_key = require("which-key")

    which_key.setup()

    which_key.add({
      { "<leader>/", group = "Comments" },
      { "<leader>/_", hidden = true },

      { "<leader>c", group = "[C]ode" },
      { "<leader>c_", hidden = true },

      { "<leader>d", group = "[D]ebug" },
      { "<leader>d_", hidden = true },

      { "<leader>e", group = "[E]xplorer" },
      { "<leader>e_", hidden = true },

      { "<leader>f", group = "[F]ind" },
      { "<leader>f_", hidden = true },

      { "<leader>g", group = "[G]it" },
      { "<leader>g_", hidden = true },

      { "<leader>J", group = "[J]ava" },
      { "<leader>J_", hidden = true },

      { "<leader>w", group = "[W]indow" },
      { "<leader>w_", hidden = true },
    })
  end,
}
