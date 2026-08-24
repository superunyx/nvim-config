
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

            actions = {
                open_file = {
                    window_picker = {
                        enable = true,
                        picker = function()
                            local wins = vim.api.nvim_tabpage_list_wins(0)
                            for _, w in ipairs(wins) do
                                local buf = vim.api.nvim_win_get_buf(w)
                                local ft = vim.bo[buf].filetype
                                local bt = vim.bo[buf].buftype
                                if ft ~= "NvimTree" and ft ~= "antigravity" and bt ~= "terminal" and bt ~= "nofile" then
                                    return w
                                end
                            end
                            
                            -- No editor window exists, so create one in the middle!
                            vim.cmd("rightbelow vsplit")
                            vim.cmd("enew")
                            local new_win = vim.api.nvim_get_current_win()
                            vim.cmd("wincmd p") -- go back to nvim-tree
                            return new_win
                        end,
                    },
                },
            },
            sort = {
                sorter = "modification_time",
            },
        })
    end
}
