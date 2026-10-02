return {
    {
        "github/copilot.vim",
        cmd = { "Copilot" },
        event = { "InsertEnter" },
        init = function()
            local function toggle_copilot()
                -- Ensure copilot is loaded if lazy-loaded
                if not package.loaded["copilot"] and vim.fn.exists(":Copilot") == 0 then
                    require("lazy").load({ plugins = { "copilot.vim" } })
                end

                local is_enabled = true
                if vim.fn.exists("*copilot#Enabled") == 1 then
                    is_enabled = (vim.fn["copilot#Enabled"]() == 1)
                elseif vim.g.copilot_enabled ~= nil then
                    is_enabled = (vim.g.copilot_enabled == 1 or vim.g.copilot_enabled == true)
                end

                if is_enabled then
                    vim.cmd("Copilot disable")
                    vim.g.copilot_enabled = 0
                    vim.notify("GitHub Copilot: Disabled", vim.log.levels.WARN, { title = "Copilot" })
                else
                    vim.cmd("Copilot enable")
                    vim.g.copilot_enabled = 1
                    vim.notify("GitHub Copilot: Enabled", vim.log.levels.INFO, { title = "Copilot" })
                end
            end

            vim.keymap.set("n", "<leader>cp", toggle_copilot, { desc = "Toggle GitHub [C]o[p]ilot" })
            vim.api.nvim_create_user_command("CopilotToggle", toggle_copilot, { desc = "Toggle GitHub Copilot" })
        end,
    },
}
