-- Ensure user binary paths are always in PATH even when launched from GUI / Hyprland
local user_bins = {
    vim.fn.expand("~/.npm-global/bin"),
    vim.fn.expand("~/.local/share/mise/installs/python/latest/bin"),
    vim.fn.expand("~/.local/share/mise/shims"),
    vim.fn.expand("~/.local/bin"),
    vim.fn.expand("~/.local/share/nvim/mason/bin"),
}
for _, dir in ipairs(user_bins) do
    if vim.fn.isdirectory(dir) == 1 and not string.find(vim.env.PATH, dir, 1, true) then
        vim.env.PATH = dir .. ":" .. vim.env.PATH
    end
end

require("config.remote_clipboard").setup()
-- Left column and similar settings 
vim.opt.number = true --display line numbers
vim.opt.relativenumber = true --display relative number line
vim.opt.numberwidth = 2
vim.opt.signcolumn = "yes"
vim.opt.wrap = false
vim.opt.scrolloff = 10
vim.opt.sidescrolloff = 8

--Tab spacing
--
vim.opt.expandtab = true
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.smartindent = true
vim.opt.breakindent = true

--General Behaviours
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0
vim.opt.backup = false
vim.opt.clipboard = "unnamedplus"
vim.opt.conceallevel = 0
vim.opt.fileencoding = "utf-8"
vim.opt.mouse = "a"
vim.opt.showmode = false
vim.opt.termguicolors = true
vim.opt.undofile = true
vim.opt.timeoutlen = 1000
vim.opt.updatetime = 100
vim.opt.writebackup = false
vim.opt.cursorline = false

--searching behav
vim.opt.hlsearch = true
vim.opt.ignorecase = true
vim.opt.smartcase = true

