return {
    {
        "neovim/nvim-lspconfig",
        ft = {
            "python",
            "html",
            "htmldjango",
            "css",
            "scss",
            "less",
            "javascript",
            "typescript",
            "javascriptreact",
            "typescriptreact",
            "json",
            "jsonc",
        },
        cmd = { "LspInfo", "LspStart", "LspRestart", "IdeToggle", "LspToggle" },
        config = function()
            local ide = require("config.ide")

            local capabilities = vim.lsp.protocol.make_client_capabilities()
            local ok_cmp, cmp_lsp = pcall(require, "cmp_nvim_lsp")
            if ok_cmp then
                capabilities = cmp_lsp.default_capabilities(capabilities)
            end
            capabilities.textDocument.completion.completionItem.snippetSupport = true

            local on_attach = function(client, bufnr)
                -- NEVER attach to Java buffers (keeps Java DSA 100% clean)
                if vim.bo[bufnr].filetype == "java" then
                    vim.schedule(function()
                        pcall(vim.lsp.buf_detach_client, bufnr, client.id)
                    end)
                    return
                end

                -- If IDE features are toggled off for this buffer/session, detach immediately
                if not ide.is_enabled(bufnr) then
                    vim.schedule(function()
                        pcall(vim.lsp.buf_detach_client, bufnr, client.id)
                    end)
                    return
                end

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

            -- 1. Setup Pyright (Python types, definitions, hover)
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

            -- 2. Setup Ruff (Python linter and quick-fixes)
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

            local get_root = function(markers)
                return function(bufnr, on_dir)
                    local name = vim.api.nvim_buf_get_name(bufnr)
                    local dir = vim.fs.root(bufnr, markers)
                    if not dir or dir == "" then
                        dir = (name ~= "" and vim.fs.dirname(name)) or vim.fn.getcwd()
                    end
                    on_dir(dir)
                end
            end

            -- 3. Setup HTML Language Server
            local html_bin = vim.fn.exepath("vscode-html-language-server")
            if html_bin ~= "" then
                vim.lsp.config("html", {
                    cmd = { html_bin, "--stdio" },
                    filetypes = { "html", "htmldjango" },
                    capabilities = capabilities,
                    on_attach = on_attach,
                    root_dir = get_root({ "package.json", ".git" }),
                })
                vim.lsp.enable("html")
            end

            -- 4. Setup CSS Language Server
            local css_bin = vim.fn.exepath("vscode-css-language-server")
            if css_bin ~= "" then
                vim.lsp.config("cssls", {
                    cmd = { css_bin, "--stdio" },
                    filetypes = { "css", "scss", "less" },
                    capabilities = capabilities,
                    on_attach = on_attach,
                    root_dir = get_root({ "package.json", ".git" }),
                })
                vim.lsp.enable("cssls")
            end

            -- 5. Setup TypeScript / JavaScript Language Server
            local ts_bin = vim.fn.exepath("typescript-language-server")
            if ts_bin ~= "" then
                vim.lsp.config("ts_ls", {
                    cmd = { ts_bin, "--stdio" },
                    filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
                    capabilities = capabilities,
                    on_attach = on_attach,
                    root_dir = get_root({ "tsconfig.json", "package.json", "jsconfig.json", ".git" }),
                })
                vim.lsp.enable("ts_ls")
            end

            -- 6. Setup Emmet Language Server (HTML/CSS abbreviation expansions)
            local emmet_bin = vim.fn.exepath("emmet-language-server")
            if emmet_bin ~= "" then
                vim.lsp.config("emmet_language_server", {
                    cmd = { emmet_bin, "--stdio" },
                    filetypes = { "html", "htmldjango", "css", "scss", "less", "javascriptreact", "typescriptreact" },
                    capabilities = capabilities,
                    on_attach = on_attach,
                    root_dir = get_root({ "package.json", ".git" }),
                })
                vim.lsp.enable("emmet_language_server")
            end

            -- Clean up idle LSP servers when closing buffers to release RAM for Java DSA
            local group = vim.api.nvim_create_augroup("LspAutoCleanup", { clear = true })
            vim.api.nvim_create_autocmd("BufDelete", {
                group = group,
                callback = function(args)
                    local ft = vim.bo[args.buf].filetype
                    if ft and ft ~= "" and ft ~= "java" then
                        vim.schedule(function()
                            local has_matching_buf = false
                            for _, b in ipairs(vim.api.nvim_list_bufs()) do
                                if vim.api.nvim_buf_is_loaded(b) and vim.bo[b].filetype == ft and b ~= args.buf then
                                    has_matching_buf = true
                                    break
                                end
                            end
                            if not has_matching_buf then
                                local servers = ide.ft_servers[ft] or {}
                                for _, s in ipairs(servers) do
                                    for _, client in ipairs(vim.lsp.get_clients({ name = s })) do
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
