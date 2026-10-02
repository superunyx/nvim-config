return {
    {
        "neovim/nvim-lspconfig",
        ft = { "python" },
        config = function()
            local capabilities = vim.lsp.protocol.make_client_capabilities()
            local ok_cmp, cmp_lsp = pcall(require, "cmp_nvim_lsp")
            if ok_cmp then
                capabilities = cmp_lsp.default_capabilities(capabilities)
            end

            local on_attach = function(client, bufnr)
                -- Diagnostics disabled for Python buffers
                -- vim.diagnostic.enable(true, { bufnr = bufnr })

                -- Setup buffer-local keymaps so they never leak to Java or other buffers
                local map = function(mode, lhs, rhs, desc)
                    vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
                end

                map("n", "<leader>ch", vim.lsp.buf.hover, "[C]ode [H]over Documentation")
                map("n", "<leader>cd", vim.lsp.buf.definition, "[C]ode Goto [D]efinition")
                map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ctions")
                map("n", "<leader>cR", vim.lsp.buf.rename, "[C]ode [R]ename")
                map("n", "<leader>cf", function()
                    vim.lsp.buf.format({ async = true })
                end, "[C]ode [F]ormat")

                local ok_telescope, builtin = pcall(require, "telescope.builtin")
                if ok_telescope then
                    map("n", "<leader>cr", builtin.lsp_references, "[C]ode Goto [R]eferences")
                    map("n", "<leader>ci", builtin.lsp_implementations, "[C]ode Goto [I]mplementations")
                end
            end

            -- Setup Pyright (Pylance core equivalent: types, definitions, hover)
            local pyright_bin = vim.fn.exepath("pyright-langserver")
            if pyright_bin ~= "" then
                vim.lsp.config("pyright", {
                    cmd = { pyright_bin, "--stdio" },
                    filetypes = { "python" },
                    capabilities = capabilities,
                    on_attach = on_attach,
                    settings = {
                        python = {
                            analysis = {
                                autoSearchPaths = true,
                                useLibraryCodeForTypes = true,
                                diagnosticMode = "openFilesOnly",
                            },
                        },
                    },
                })
                vim.lsp.enable("pyright")
            end

            -- Setup Ruff (Linter and quick-fixes)
            local ruff_bin = vim.fn.exepath("ruff")
            if ruff_bin ~= "" then
                vim.lsp.config("ruff", {
                    cmd = { ruff_bin, "server" },
                    filetypes = { "python" },
                    capabilities = capabilities,
                    on_attach = on_attach,
                })
                vim.lsp.enable("ruff")
            end

            -- Unload LSP servers when closing the last Python buffer to release resources
            local group = vim.api.nvim_create_augroup("PythonLspCleanup", { clear = true })
            vim.api.nvim_create_autocmd("BufDelete", {
                group = group,
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
                                for _, client in ipairs(vim.lsp.get_clients()) do
                                    if client.name == "pyright" or client.name == "ruff" then
                                        client:stop()
                                    end
                                end
                            end
                        end)
                    end
                end,
            })
        end,
    },
}
