
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
            hijack_cursor = true,
            hijack_directories = {
                enable = true,
                auto_open = true,
            },
            sync_root_with_cwd = true,
            auto_reload_on_write = true,
            view = {
                preserve_window_proportions = true,
                cursorline = true,
            },
            on_attach = function(bufnr)
                local api = require("nvim-tree.api")
                api.config.mappings.default_on_attach(bufnr)
                vim.keymap.set('n', 'j', 'j', { buffer = bufnr, noremap = true, silent = true, nowait = true })
                vim.keymap.set('n', 'k', 'k', { buffer = bufnr, noremap = true, silent = true, nowait = true })
            end,

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

        -- Ensure cursor and focus are inside nvim-tree immediately when opening a directory with :e <folder>
        vim.api.nvim_create_autocmd("BufEnter", {
            nested = true,
            callback = function(args)
                if vim.fn.isdirectory(args.file) == 1 then
                    local api = require("nvim-tree.api")
                    if not api.tree.is_visible() then
                        api.tree.open({ path = args.file })
                    else
                        api.tree.focus()
                    end
                end
            end,
        })
    end
}
