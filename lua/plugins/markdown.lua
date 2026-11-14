return {
    -- In-buffer Markdown & Checkbox rendering
    {
        "MeanderingProgrammer/render-markdown.nvim",
        ft = { "markdown" },
        dependencies = {
            "nvim-treesitter/nvim-treesitter",
            "nvim-tree/nvim-web-devicons",
        },
        opts = {
            anti_conceal = {
                enabled = true,
            },
            heading = {
                enabled = true,
                sign = false,
            },
            code = {
                enabled = true,
                sign = false,
                style = "full",
                border = "thin",
            },
            bullet = {
                enabled = true,
                icons = { "●", "○", "◆", "◇" },
            },
            checkbox = {
                enabled = true,
                position = "inline",
                unchecked = {
                    icon = "󰄱 ",
                    highlight = "RenderMarkdownUnchecked",
                },
                checked = {
                    icon = "󰱒 ",
                    highlight = "RenderMarkdownChecked",
                },
                custom = {
                    todo = {
                        raw = "[-]",
                        rendered = "󰥔 ",
                        highlight = "RenderMarkdownTodo",
                    },
                    canceled = {
                        raw = "[~]",
                        rendered = "󰰱 ",
                        highlight = "RenderMarkdownDash",
                    },
                    important = {
                        raw = "[!]",
                        rendered = " ",
                        highlight = "DiagnosticWarn",
                    },
                },
            },
        },
        config = function(_, opts)
            require("render-markdown").setup(opts)
        end,
    },

    -- Markdown editing & nested checklist management
    {
        "tadmccorkle/markdown.nvim",
        ft = { "markdown" },
        opts = {
            -- Disable default mappings that might conflict; we set explicit, intuitive buffer-local mappings below
            mappings = {
                inline_surround_toggle = "gs",
                inline_surround_toggle_line = "gss",
                inline_surround_delete = "ds",
                inline_surround_change = "cs",
                link_add = "gl",
                link_follow = "gx",
                go_curr_heading = "]c",
                go_parent_heading = "]p",
                go_next_heading = "]]",
                go_prev_heading = "[[",
            },
            on_attach = function(bufnr)
                -- Use 2-space indentation in markdown for clean nested checklists
                vim.bo[bufnr].shiftwidth = 2
                vim.bo[bufnr].tabstop = 2
                vim.bo[bufnr].softtabstop = 2
                vim.bo[bufnr].expandtab = true

                --- Parse a markdown line for a checklist item
                ---@param line string
                ---@return string? indent, string? bullet, string? state, string? rest
                local function parse_checkbox(line)
                    local indent, bullet, state, rest = line:match("^(%s*)([%-%*%+]%s+)%[(.)%](.*)$")
                    if indent then
                        return indent, bullet, state, rest
                    end
                    indent, bullet, state, rest = line:match("^(%s*)(%d+%.%s+)%[(.)%](.*)$")
                    if indent then
                        return indent, bullet, state, rest
                    end
                    return nil
                end

                --- Parse a plain list line (without checkbox)
                ---@param line string
                ---@return string? indent, string? bullet, string? rest
                local function parse_list(line)
                    local indent, bullet, rest = line:match("^(%s*)([%-%*%+]%s+)(.*)$")
                    if indent then
                        return indent, bullet, rest
                    end
                    indent, bullet, rest = line:match("^(%s*)(%d+%.%s+)(.*)$")
                    if indent then
                        return indent, bullet, rest
                    end
                    return nil
                end

                --- Update ancestor checkboxes based on their nested children's states
                ---@param lines string[]
                ---@param child_idx integer (1-based)
                local function update_ancestors(lines, child_idx)
                    local c_indent = parse_checkbox(lines[child_idx])
                    if not c_indent then
                        return
                    end
                    local curr_width = #c_indent

                    -- Walk upwards to find parent checklist items
                    for i = child_idx - 1, 1, -1 do
                        local l = lines[i]
                        if l:match("^%s*$") then
                            break
                        end
                        local p_indent, p_bullet, p_state, p_rest = parse_checkbox(l)
                        if p_indent and #p_indent < curr_width then
                            -- Found parent at index i; check all its nested checklist descendants
                            local parent_width = #p_indent
                            local total_children = 0
                            local checked_children = 0
                            for j = i + 1, #lines do
                                local cl = lines[j]
                                if cl:match("^%s*$") then
                                    break
                                end
                                local ch_indent, _, ch_state = parse_checkbox(cl)
                                if ch_indent then
                                    if #ch_indent <= parent_width then
                                        break
                                    end
                                    total_children = total_children + 1
                                    if ch_state == "x" or ch_state == "X" then
                                        checked_children = checked_children + 1
                                    end
                                else
                                    local non_ws = cl:match("^(%s*)%S")
                                    if non_ws and #non_ws <= parent_width then
                                        break
                                    end
                                end
                            end

                            if total_children > 0 then
                                local new_parent_state = p_state
                                if checked_children == total_children then
                                    new_parent_state = "x"
                                elseif p_state == "x" or p_state == "X" then
                                    new_parent_state = " "
                                end
                                if new_parent_state ~= p_state then
                                    lines[i] = p_indent .. p_bullet .. "[" .. new_parent_state .. "]" .. p_rest
                                end
                            end
                            curr_width = parent_width
                            if curr_width == 0 then
                                break
                            end
                        end
                    end
                end

                --- Toggle checkbox on a line (1-based) and cascade to nested children & parents
                ---@param lnum integer
                ---@param cascade_children boolean
                local function toggle_checkbox_line(lnum, cascade_children)
                    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
                    local line = lines[lnum]
                    if not line then
                        return
                    end

                    local indent, bullet, state, rest = parse_checkbox(line)
                    if indent then
                        local new_state = (state == " " or state == "-") and "x" or " "
                        lines[lnum] = indent .. bullet .. "[" .. new_state .. "]" .. rest

                        -- Cascade to nested child checkboxes if enabled
                        if cascade_children then
                            local base_width = #indent
                            for j = lnum + 1, #lines do
                                local cl = lines[j]
                                if cl:match("^%s*$") then
                                    break
                                end
                                local c_indent, c_bullet, _, c_rest = parse_checkbox(cl)
                                if c_indent then
                                    if #c_indent <= base_width then
                                        break
                                    end
                                    lines[j] = c_indent .. c_bullet .. "[" .. new_state .. "]" .. c_rest
                                else
                                    local non_ws = cl:match("^(%s*)%S")
                                    if non_ws and #non_ws <= base_width then
                                        break
                                    end
                                end
                            end
                        end

                        -- Update parent checkboxes if all children are checked/unchecked
                        update_ancestors(lines, lnum)
                    else
                        -- Not a checkbox yet: convert plain list item or plain line into `- [ ] `
                        local l_indent, l_bullet, l_rest = parse_list(line)
                        if l_indent then
                            lines[lnum] = l_indent .. l_bullet .. "[ ] " .. l_rest
                        else
                            local ws, text = line:match("^(%s*)(.*)$")
                            lines[lnum] = (ws or "") .. "- [ ] " .. (text or "")
                        end
                        update_ancestors(lines, lnum)
                    end

                    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
                end

                --- Set specific state (e.g. "-" for in-progress) on current line
                ---@param target_state string
                local function set_checkbox_state(target_state)
                    local lnum = vim.api.nvim_win_get_cursor(0)[1]
                    local line = vim.api.nvim_buf_get_lines(bufnr, lnum - 1, lnum, false)[1]
                    if not line then
                        return
                    end
                    local indent, bullet, state, rest = parse_checkbox(line)
                    if indent then
                        local next_state = (state == target_state) and " " or target_state
                        local new_line = indent .. bullet .. "[" .. next_state .. "]" .. rest
                        vim.api.nvim_buf_set_lines(bufnr, lnum - 1, lnum, false, { new_line })
                    else
                        toggle_checkbox_line(lnum, false)
                    end
                end

                local map = function(mode, lhs, rhs, desc)
                    vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
                end

                -- Toggle checkbox (with nested checklist cascade)
                map("n", "<leader>mx", function()
                    local lnum = vim.api.nvim_win_get_cursor(0)[1]
                    toggle_checkbox_line(lnum, true)
                end, "[M]arkdown Toggle Checkbox (and nested children)")

                map("n", "<C-Space>", function()
                    local lnum = vim.api.nvim_win_get_cursor(0)[1]
                    toggle_checkbox_line(lnum, true)
                end, "Markdown Toggle Checkbox")

                -- Visual mode: toggle checkboxes on all selected lines
                map("v", "<leader>mx", function()
                    local start_line = vim.fn.line("v")
                    local end_line = vim.fn.line(".")
                    if start_line > end_line then
                        start_line, end_line = end_line, start_line
                    end
                    for l = start_line, end_line do
                        toggle_checkbox_line(l, false)
                    end
                    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
                end, "[M]arkdown Toggle Checkboxes in Selection")

                -- Toggle in-progress [-] state
                map("n", "<leader>mp", function()
                    set_checkbox_state("-")
                end, "[M]arkdown Checkbox In-[P]rogress [-]")

                -- Insert sibling checklist item below at same nesting level
                map("n", "<leader>mo", function()
                    local lnum = vim.api.nvim_win_get_cursor(0)[1]
                    local line = vim.api.nvim_buf_get_lines(bufnr, lnum - 1, lnum, false)[1] or ""
                    local indent, bullet = parse_checkbox(line)
                    local new_line
                    if indent then
                        new_line = indent .. bullet .. "[ ] "
                    else
                        local ws = line:match("^(%s*)") or ""
                        new_line = ws .. "- [ ] "
                    end
                    vim.api.nvim_buf_set_lines(bufnr, lnum, lnum, false, { new_line })
                    vim.api.nvim_win_set_cursor(0, { lnum + 1, #new_line })
                    vim.cmd("startinsert!")
                end, "[M]arkdown Add Checklist Item Below")

                -- Insert nested child checklist item below current line
                map("n", "<leader>mn", function()
                    local lnum = vim.api.nvim_win_get_cursor(0)[1]
                    local line = vim.api.nvim_buf_get_lines(bufnr, lnum - 1, lnum, false)[1] or ""
                    local indent, bullet = parse_checkbox(line)
                    local sw = string.rep(" ", vim.bo[bufnr].shiftwidth)
                    local new_line
                    if indent then
                        new_line = indent .. sw .. bullet .. "[ ] "
                    else
                        local ws = line:match("^(%s*)") or ""
                        new_line = ws .. "- [ ] "
                    end
                    vim.api.nvim_buf_set_lines(bufnr, lnum, lnum, false, { new_line })
                    vim.api.nvim_win_set_cursor(0, { lnum + 1, #new_line })
                    vim.cmd("startinsert!")
                end, "[M]arkdown Add [N]ested Checklist Item")

                -- Toggle RenderMarkdown preview
                map("n", "<leader>mr", "<cmd>RenderMarkdown toggle<CR>", "[M]arkdown [R]ender Toggle")

                -- Smart <CR> in Insert mode: continue checklists / lists at current nesting level,
                -- or un-nest / exit checklist when pressing <CR> on an empty checkbox item
                vim.keymap.set("i", "<CR>", function()
                    local ok_cmp, cmp = pcall(require, "cmp")
                    if ok_cmp and cmp.visible() then
                        cmp.confirm({ select = true })
                        return
                    end

                    local pos = vim.api.nvim_win_get_cursor(0)
                    local row, col = pos[1], pos[2]
                    local line = vim.api.nvim_get_current_line()

                    -- Check if current line is a checkbox item
                    local indent, bullet, _, rest = parse_checkbox(line)
                    if indent then
                        -- If the checkbox item has no text (`- [ ] `)
                        if rest:match("^%s*$") then
                            local sw = vim.bo[bufnr].shiftwidth
                            if #indent >= sw then
                                -- Dedent nested empty checkbox by one level
                                local new_indent = indent:sub(1, #indent - sw)
                                local new_line = new_indent .. bullet .. "[ ] "
                                vim.api.nvim_set_current_line(new_line)
                                vim.api.nvim_win_set_cursor(0, { row, #new_line })
                            else
                                -- At top level: clear the empty checkbox marker
                                vim.api.nvim_set_current_line("")
                                vim.api.nvim_win_set_cursor(0, { row, 0 })
                            end
                            return
                        end

                        -- If cursor is at or after the checkbox prefix, continue with a new unchecked item at same nesting
                        local prefix_len = #indent + #bullet + 4 -- "[ ] " is 4 chars
                        if col >= prefix_len - 1 then
                            local before = line:sub(1, col)
                            local after = line:sub(col + 1)
                            local next_line = indent .. bullet .. "[ ] " .. after
                            vim.api.nvim_buf_set_lines(bufnr, row - 1, row, false, { before, next_line })
                            vim.api.nvim_win_set_cursor(0, { row + 1, #indent + #bullet + 4 })
                            return
                        end
                    end

                    -- Check if current line is a plain list item
                    local l_indent, l_bullet, l_rest = parse_list(line)
                    if l_indent then
                        if l_rest:match("^%s*$") then
                            local sw = vim.bo[bufnr].shiftwidth
                            if #l_indent >= sw then
                                local new_indent = l_indent:sub(1, #l_indent - sw)
                                local new_line = new_indent .. l_bullet
                                vim.api.nvim_set_current_line(new_line)
                                vim.api.nvim_win_set_cursor(0, { row, #new_line })
                            else
                                vim.api.nvim_set_current_line("")
                                vim.api.nvim_win_set_cursor(0, { row, 0 })
                            end
                            return
                        end

                        local prefix_len = #l_indent + #l_bullet
                        if col >= prefix_len then
                            local before = line:sub(1, col)
                            local after = line:sub(col + 1)
                            local next_number_bullet = l_bullet
                            local num = l_bullet:match("^(%d+)%.%s+$")
                            if num then
                                next_number_bullet = tostring(tonumber(num) + 1) .. ". "
                            end
                            local next_line = l_indent .. next_number_bullet .. after
                            vim.api.nvim_buf_set_lines(bufnr, row - 1, row, false, { before, next_line })
                            vim.api.nvim_win_set_cursor(0, { row + 1, #l_indent + #next_number_bullet })
                            return
                        end
                    end

                    -- Default <CR> behavior
                    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<CR>", true, false, true), "n", false)
                end, { buffer = bufnr, silent = true, desc = "Markdown smart newline for nested checklists" })

                -- Smart <Tab> / <S-Tab> on list/checkbox lines in Normal & Insert mode to nest / un-nest checklists
                map("n", "<Tab>", function()
                    local line = vim.api.nvim_get_current_line()
                    if parse_checkbox(line) or parse_list(line) then
                        vim.cmd("normal! >>$")
                    else
                        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Tab>", true, false, true), "n", false)
                    end
                end, "Markdown indent/nest checklist item")

                map("n", "<S-Tab>", function()
                    local line = vim.api.nvim_get_current_line()
                    if parse_checkbox(line) or parse_list(line) then
                        vim.cmd("normal! <<$")
                    end
                end, "Markdown dedent/un-nest checklist item")

                vim.keymap.set("i", "<Tab>", function()
                    local ok_cmp, cmp = pcall(require, "cmp")
                    if ok_cmp and cmp.visible() then
                        cmp.select_next_item()
                        return
                    end
                    local line = vim.api.nvim_get_current_line()
                    if parse_checkbox(line) or parse_list(line) then
                        local pos = vim.api.nvim_win_get_cursor(0)
                        local sw = vim.bo[bufnr].shiftwidth
                        local new_line = string.rep(" ", sw) .. line
                        vim.api.nvim_set_current_line(new_line)
                        vim.api.nvim_win_set_cursor(0, { pos[1], pos[2] + sw })
                        return
                    end
                    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Tab>", true, false, true), "n", false)
                end, { buffer = bufnr, silent = true, desc = "Markdown nest checklist item in insert mode" })

                vim.keymap.set("i", "<S-Tab>", function()
                    local ok_cmp, cmp = pcall(require, "cmp")
                    if ok_cmp and cmp.visible() then
                        cmp.select_prev_item()
                        return
                    end
                    local line = vim.api.nvim_get_current_line()
                    if parse_checkbox(line) or parse_list(line) then
                        local pos = vim.api.nvim_win_get_cursor(0)
                        local sw = vim.bo[bufnr].shiftwidth
                        local removed = 0
                        local new_line = line
                        for _ = 1, sw do
                            if new_line:sub(1, 1) == " " then
                                new_line = new_line:sub(2)
                                removed = removed + 1
                            else
                                break
                            end
                        end
                        if removed > 0 then
                            vim.api.nvim_set_current_line(new_line)
                            vim.api.nvim_win_set_cursor(0, { pos[1], math.max(0, pos[2] - removed) })
                        end
                        return
                    end
                    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<S-Tab>", true, false, true), "n", false)
                end, { buffer = bufnr, silent = true, desc = "Markdown un-nest checklist item in insert mode" })
            end,
        },
    },
}
