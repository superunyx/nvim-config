return {
    'goolord/alpha-nvim',
    config = function()
        local dashboard = require('alpha.themes.dashboard')

        dashboard.config.layout = {
            { type = "padding", val = 1 },
            dashboard.section.header,
            { type = "padding", val = 2 },
            dashboard.section.buttons,
            dashboard.section.footer,
        }

        local alpha = require('alpha')

        -- Guard against alpha-nvim upstream race condition where WinResized
        -- tries to redraw a buffer that has just been wiped/closed
        local orig_draw = alpha.draw
        alpha.draw = function(conf, state)
            if not state or not state.buffer or not vim.api.nvim_buf_is_valid(state.buffer) then
                return
            end
            pcall(orig_draw, conf, state)
        end

        local orig_redraw = alpha.redraw
        alpha.redraw = function(conf, state)
            if not state or not state.buffer or not vim.api.nvim_buf_is_valid(state.buffer) then
                return
            end
            pcall(orig_redraw, conf, state)
        end

        alpha.setup(dashboard.config)

        local function dismiss_alpha()
            pcall(vim.api.nvim_del_augroup_by_name, "alpha_temp")
            local wins = vim.api.nvim_list_wins()
            local alpha_wins = {}
            local other_editor_wins = {}

            for _, win in ipairs(wins) do
                if vim.api.nvim_win_is_valid(win) then
                    local buf = vim.api.nvim_win_get_buf(win)
                    local ft = vim.bo[buf].filetype
                    local bt = vim.bo[buf].buftype
                    if ft == "alpha" then
                        table.insert(alpha_wins, win)
                    elseif ft ~= "NvimTree" and ft ~= "antigravity" and bt ~= "terminal" and bt ~= "nofile" then
                        table.insert(other_editor_wins, win)
                    end
                end
            end

            if #alpha_wins == 0 then
                return
            end

            for _, win in ipairs(alpha_wins) do
                if vim.api.nvim_win_is_valid(win) then
                    if #other_editor_wins > 0 then
                        pcall(vim.api.nvim_win_close, win, true)
                    else
                        vim.api.nvim_win_call(win, function()
                            vim.cmd("enew")
                        end)
                        table.insert(other_editor_wins, win)
                    end
                end
            end
        end

        -- Dismiss Alpha home screen when changing directory (e.g. :cd)
        vim.api.nvim_create_autocmd("DirChanged", {
            desc = "Dismiss Alpha dashboard on directory change (:cd)",
            callback = function()
                dismiss_alpha()
            end,
        })

        -- Close orphan Alpha dashboard when editing a file in another window
        vim.api.nvim_create_autocmd("BufEnter", {
            desc = "Close orphan Alpha dashboard when editing a file",
            callback = function(args)
                local cur_ft = vim.bo[args.buf].filetype
                local cur_bt = vim.bo[args.buf].buftype
                local name = vim.api.nvim_buf_get_name(args.buf)
                if (cur_ft ~= "" or name ~= "") and cur_ft ~= "alpha" and cur_ft ~= "NvimTree" and cur_ft ~= "antigravity" and cur_bt == "" then
                    dismiss_alpha()
                end
            end,
        })
    end,
}
