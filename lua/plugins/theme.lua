-- Loads the active Omarchy theme from ~/.local/state/omarchy/current/theme/neovim.lua
-- and adapts it for standalone lazy.nvim (stripping LazyVim/LazyVim and applying the colorscheme).
local theme_file = vim.fn.expand("~/.local/state/omarchy/current/theme/neovim.lua")

if vim.fn.filereadable(theme_file) == 1 then
	local ok, theme_plugins = pcall(dofile, theme_file)
	if ok and type(theme_plugins) == "table" then
		local colorscheme = nil
		local plugins = {}

		for _, plugin in ipairs(theme_plugins) do
			if type(plugin) == "table" then
				if plugin[1] == "LazyVim/LazyVim" then
					if plugin.opts and plugin.opts.colorscheme then
						colorscheme = plugin.opts.colorscheme
					end
				else
					table.insert(plugins, plugin)
				end
			end
		end

		if #plugins > 0 then
			plugins[1].lazy = false
			plugins[1].priority = 1000

			if colorscheme then
				local original_config = plugins[1].config
				plugins[1].config = function(plugin_spec, opts)
					if type(original_config) == "function" then
						original_config(plugin_spec, opts)
					end
					pcall(vim.cmd.colorscheme, colorscheme)
				end
			end

			return plugins
		end
	end
end

-- Fallback if Omarchy theme file is not available
return {
	"ribru17/bamboo.nvim",
	lazy = false,
	priority = 1000,
	config = function()
		require("bamboo").setup({})
		require("bamboo").load()
	end,
}
