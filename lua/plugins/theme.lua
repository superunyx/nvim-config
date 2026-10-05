-- Loads the active Omarchy theme from ~/.local/state/omarchy/current/theme/neovim.lua
-- (or ~/.config/omarchy/current/theme/neovim.lua)
-- and adapts it for standalone lazy.nvim (stripping LazyVim/LazyVim and applying the colorscheme).
local theme_file = vim.fn.expand("~/.local/state/omarchy/current/theme/neovim.lua")
if vim.fn.filereadable(theme_file) == 0 then
	local alt_file = vim.fn.expand("~/.config/omarchy/current/theme/neovim.lua")
	if vim.fn.filereadable(alt_file) == 1 then
		theme_file = alt_file
	end
end

if vim.fn.filereadable(theme_file) == 1 then
	local ok, theme_plugins = pcall(dofile, theme_file)
	if ok and type(theme_plugins) == "table" then
		local colorscheme = nil
		local extra_opts = {}
		local plugins = {}

		for _, plugin in ipairs(theme_plugins) do
			if type(plugin) == "table" then
				if plugin[1] == "LazyVim/LazyVim" then
					if plugin.opts then
						if plugin.opts.colorscheme then
							colorscheme = plugin.opts.colorscheme
						end
						for k, v in pairs(plugin.opts) do
							if k ~= "colorscheme" then
								extra_opts[k] = v
							end
						end
					end
				else
					table.insert(plugins, plugin)
				end
			end
		end

		if #plugins > 0 then
			plugins[1].lazy = false
			plugins[1].priority = 1000

			if next(extra_opts) then
				plugins[1].opts = vim.tbl_deep_extend("force", plugins[1].opts or {}, extra_opts)
			end

			if colorscheme then
				local original_config = plugins[1].config
				plugins[1].config = function(plugin_spec, opts)
					if type(original_config) == "function" then
						original_config(plugin_spec, opts)
					else
						local modname = plugin_spec.main or plugin_spec.name
						if not modname and plugin_spec[1] then
							modname = plugin_spec[1]:match("/([^/]+)$"):gsub("%.nvim$", "")
						end
						if modname then
							local ok_mod, mod = pcall(require, modname)
							if ok_mod and type(mod) == "table" and type(mod.setup) == "function" then
								mod.setup(opts or {})
							end
						end
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
	"bjarneo/aether.nvim",
	name = "aether",
	lazy = false,
	priority = 1000,
	config = function()
		pcall(vim.cmd.colorscheme, "aether")
	end,
}
