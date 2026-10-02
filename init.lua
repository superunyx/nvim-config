vim.opt.clipboard = "unnamedplus"

-- Neovim 0.12 compatibility for plugins expecting vim.treesitter.language.ft_to_lang
if vim.treesitter and vim.treesitter.language and not vim.treesitter.language.ft_to_lang then
    vim.treesitter.language.ft_to_lang = vim.treesitter.language.get_lang
end

-- Declare the path where lazy will clone plugin code
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

-- Check to see if lazy itself has been cloned, if not clone it into the lazy.nvim directory
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable", -- latest stable release
		lazypath,
	})
end

-- Add the path to the lazy plugin repositories to the vim runtime path
vim.opt.rtp:prepend(lazypath)


-- Declare a few options for lazy
local opts = {
	change_detection = {
		-- Don't notify us every time a change is made to the configuration
		notify = false,
	},
	checker = {
		-- Automatically check for package updates
		enabled = true,
		-- Don't spam us with notification every time there is an update available
		notify = false,
	},
}


-- Load the options from the config/options.lua file
require("config.options")
-- Load the keymaps from the config/keymaps.lua file
require("config.keymaps")
-- Load the auto commands from the config/autocmds.lua file
--require("config.autocmds")
-- Setup lazy, this should always be last
-- Tell lazy that all plugin specs are found in the plugins directory
-- Pass it the options we specified above
require("lazy").setup("plugins", opts)
require("config.venv").setup()
require("config.floaterminal")
require("config.antigravity")
require("config.folder_bookmarks")



-- Disable diagnostics globally
vim.diagnostic.enable(false)

--[[
-- Keep diagnostics disabled by default, only enable for Python
vim.api.nvim_create_autocmd("FileType", {
    callback = function(args)
        if vim.bo[args.buf].filetype ~= "python" then
            vim.diagnostic.enable(false, { bufnr = args.buf })
        else
            vim.diagnostic.enable(true, { bufnr = args.buf })
        end
    end,
})
--]]
