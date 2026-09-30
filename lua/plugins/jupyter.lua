return {
    -- Interactive Jupyter Kernel runner (Molten)
    {
        "benlubas/molten-nvim",
        version = "^1.0.0",
        build = ":UpdateRemotePlugins",
        ft = { "python", "ipynb" },
        cmd = {
            "MoltenInit",
            "MoltenDeinit",
            "MoltenEvaluateCell",
            "MoltenReevaluateCell",
            "MoltenEvaluateVisual",
            "MoltenShowOutput",
            "MoltenHideOutput",
        },
        init = function()
            vim.g.molten_auto_open_output = false
            vim.g.molten_output_win_max_height = 20
            vim.g.molten_output_win_max_width = 100
            vim.g.molten_wrap_output = true
            vim.g.molten_virt_text_output = true

            -- Transparent .ipynb notebook handling using the jupytext CLI
            local group = vim.api.nvim_create_augroup("JupytextNotebook", { clear = true })
            vim.api.nvim_create_autocmd({ "BufReadCmd" }, {
                group = group,
                pattern = "*.ipynb",
                callback = function(args)
                    local filepath = vim.fn.expand("<afile>:p")
                    local res = vim.system({ "jupytext", "--to", "py:percent", "--output", "-", filepath }, { text = true }):wait()
                    if res.code == 0 then
                        local lines = vim.split(res.stdout, "\n", { plain = true })
                        if #lines > 0 and lines[#lines] == "" then
                            table.remove(lines, #lines)
                        end
                        vim.api.nvim_buf_set_lines(args.buf, 0, -1, false, lines)
                        vim.bo[args.buf].filetype = "python"
                        vim.bo[args.buf].modified = false
                    end
                end,
            })

            vim.api.nvim_create_autocmd({ "BufWriteCmd" }, {
                group = group,
                pattern = "*.ipynb",
                callback = function(args)
                    local filepath = vim.fn.expand("<afile>:p")
                    local lines = vim.api.nvim_buf_get_lines(args.buf, 0, -1, false)
                    local content = table.concat(lines, "\n")
                    local res = vim.system(
                        { "jupytext", "--from", "py:percent", "--to", "ipynb", "--output", filepath },
                        { stdin = content }
                    ):wait()
                    if res.code == 0 then
                        vim.bo[args.buf].modified = false
                    end
                end,
            })
        end,
        config = function()
            -- Keymaps for Jupyter / interactive execution (only set on python buffers)
            local function map_python_keys(bufnr)
                local map = function(mode, lhs, rhs, desc)
                    vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
                end

                map("n", "<leader>mi", ":MoltenInit python3<CR>", "[M]olten [I]nit (Start Jupyter Kernel)")
                map("n", "<leader>mq", ":MoltenDeinit<CR>", "[M]olten [Q]uit (Stop Kernel)")
                map("n", "<leader>mr", ":MoltenReevaluateCell<CR>", "[M]olten [R]un Cell")
                map("v", "<leader>mr", ":<C-u>MoltenEvaluateVisual<CR>", "[M]olten [R]un Visual Selection")
                map("n", "<leader>mo", ":MoltenShowOutput<CR>", "[M]olten [O]utput Show")
                map("n", "<leader>mh", ":MoltenHideOutput<CR>", "[M]olten [H]ide Output")
            end

            -- Attach keymaps whenever a python buffer is active
            vim.api.nvim_create_autocmd("FileType", {
                pattern = { "python", "ipynb" },
                callback = function(args)
                    map_python_keys(args.buf)
                end,
            })

            -- Clean up Molten kernel when all python buffers are closed
            vim.api.nvim_create_autocmd("BufDelete", {
                callback = function(args)
                    if vim.bo[args.buf].filetype == "python" then
                        vim.schedule(function()
                            local has_python_buf = false
                            for _, b in ipairs(vim.api.nvim_list_bufs()) do
                                if vim.api.nvim_buf_is_loaded(b) and vim.bo[b].filetype == "python" and b ~= args.buf then
                                    has_python_buf = true
                                    break
                                end
                            end
                            if not has_python_buf then
                                pcall(vim.cmd, "MoltenDeinit")
                            end
                        end)
                    end
                end,
            })
        end,
    },
}
