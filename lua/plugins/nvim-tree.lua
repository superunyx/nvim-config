
return {
    "nvim-tree/nvim-tree.lua",
    config = function()
        vim.keymap.set('n', '<leader>e', "<cmd>NvimTreeToggle<CR>", { desc = "Toggle [E]xplorer" })

        require("nvim-tree").setup({
            filters = {
                dotfiles = false,         -- keep dotfiles visible or hidden
                custom = { "*.class" },   -- hide all .class files
            },
            hijack_netrw = true,
            auto_reload_on_write = true,

            sort = {
                sorter = "modification_time",
            },
        })
    end
}
