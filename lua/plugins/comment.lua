return {
	"numToStr/Comment.nvim",
	event = { "BufReadPre", "BufNewFile" },
	-- dependencies = {
	-- 	-- plugin to allow us to automatically comment tsx elements with the comment plugin
	-- 	"JoosepAlviste/nvim-ts-context-commentstring",
	-- },
	config = function()
		-- Set a vim motion to <Space> + / to comment the line under the cursor in normal mode
		vim.keymap.set("n", "<leader>/", "<Plug>(comment_toggle_linewise_current)", { desc = "Comment Line" })
		-- Set a vim motion to <Space> + / to comment all the lines selected in visual mode
		vim.keymap.set("v", "<leader>/", "<Plug>(comment_toggle_linewise_visual)", { desc = "Comment Selected" })

		-- gain access to the comment plugins functions
		local comment = require("Comment")

		-- setup the comment plugin
		comment.setup({})
	end,
}
