return {
    {
        "lewis6991/gitsigns.nvim",
        config = function()
            -- setup gitsigns with diff highlights to show + and - clearly
            require("gitsigns").setup({
                signs = {
                    add          = { text = '+' },
                    change       = { text = '~' },
                    delete       = { text = '-' },
                    topdelete    = { text = '‾' },
                    changedelete = { text = '~' },
                },
                signcolumn = true,  -- Show +/- in the left column
                linehl     = true,  -- Highlight the whole background of changed lines
                word_diff  = true,  -- Highlight specific words changed inline
            })

            -- Set a vim motion to <Space> + g + h to preview changes to the file under the cursor in normal mode
            vim.keymap.set("n", "<leader>gh", ":Gitsigns preview_hunk<CR>", {desc="[G]it Preview [H]unk"})
            vim.keymap.set("n", "<leader>gd", ":Gitsigns toggle_linehl<CR>", {desc="[G]it Toggle [D]iff highlight"})
            vim.keymap.set("n", "<leader>gw", ":Gitsigns toggle_word_diff<CR>", {desc="[G]it Toggle [W]ord diff highlight"})
        end
    },
    {
        "tpope/vim-fugitive",
        config = function()
            -- Set a vim motion to <Space> + g + b to view the most recent contributers to the file
            vim.keymap.set("n", "<leader>gb", ":Git blame<cr>", {desc="[G]it [B]lame"})
            -- Set a vim motion to <Space> + g + <Shift>A to all files changed to the staging area
            vim.keymap.set("n", "<leader>gA", ":Git add .<cr>", {desc = "[G]it Add [A]ll"})
            -- Set a vim motion to <Space> + g + a to add the current file and changes to the staging area
            vim.keymap.set("n", "<leader>ga", "Git add", {desc = "[G]it [A]dd"})
            -- Set a vim motion to <Space> + g + c to commit the current chages
            vim.keymap.set("n", "<leader>gc", ":Git commit", {desc = "[G]it [C]ommit"})
            -- Set a vim motion to <Space> + g + p to push the commited changes to the remote repository
            vim.keymap.set("n", "<leader>gp", "Git push", {desc = "[G]it [P]ush"})
        end
    }
}
