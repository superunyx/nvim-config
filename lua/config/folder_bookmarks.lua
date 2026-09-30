local M = {}

local data_file = vim.fn.stdpath("data") .. "/folder_bookmarks.json"

local function load_bookmarks()
    local f = io.open(data_file, "r")
    if not f then
        return {}
    end
    local content = f:read("*a")
    f:close()
    local ok, list = pcall(vim.json.decode, content)
    if ok and type(list) == "table" then
        return list
    end
    return {}
end

local function save_bookmarks(list)
    local f = io.open(data_file, "w")
    if not f then
        return
    end
    f:write(vim.json.encode(list))
    f:close()
end

function M.add_bookmark(custom_path)
    local dir
    if custom_path and custom_path ~= "" then
        dir = vim.fn.fnamemodify(vim.fn.expand(custom_path), ":p")
    else
        local cur_file = vim.fn.expand("%:p")
        if cur_file ~= "" then
            dir = vim.fn.fnamemodify(cur_file, ":p:h")
        else
            dir = vim.fn.getcwd()
        end
    end

    -- Normalize directory path (remove trailing slash)
    dir = vim.fs.normalize(dir)
    if vim.fn.isdirectory(dir) ~= 1 then
        vim.notify("Not a valid directory: " .. dir, vim.log.levels.WARN)
        return
    end

    local bookmarks = load_bookmarks()
    for _, b in ipairs(bookmarks) do
        if b == dir then
            vim.notify("Folder already bookmarked: " .. dir, vim.log.levels.INFO)
            return
        end
    end

    table.insert(bookmarks, dir)
    save_bookmarks(bookmarks)
    vim.notify("Bookmarked folder: " .. dir, vim.log.levels.INFO)
end

function M.open_picker()
    local bookmarks = load_bookmarks()
    if #bookmarks == 0 then
        vim.notify("No folder bookmarks yet! Use <leader>bm to bookmark the current folder.", vim.log.levels.WARN)
        return
    end

    local pickers = require("telescope.pickers")
    local finders = require("telescope.finders")
    local conf = require("telescope.config").values
    local actions = require("telescope.actions")
    local action_state = require("telescope.actions.state")
    local themes = require("telescope.themes")

    local function make_finder()
        return finders.new_table({
            results = bookmarks,
            entry_maker = function(entry)
                local name = vim.fn.fnamemodify(entry, ":t")
                if name == "" then
                    name = entry
                end
                local home = vim.fn.expand("~")
                local display_path = entry
                if vim.startswith(entry, home) then
                    display_path = "~" .. entry:sub(#home + 1)
                end
                return {
                    value = entry,
                    display = string.format("📁 %-20s  %s", name, display_path),
                    ordinal = name .. " " .. display_path,
                }
            end,
        })
    end

    local opts = themes.get_dropdown({
        prompt_title = "Bookmarked Folders (Enter: open | Ctrl+d: delete)",
        finder = make_finder(),
        sorter = conf.generic_sorter({}),
        attach_mappings = function(prompt_bufnr, map)
            -- Open folder on <CR>
            actions.select_default:replace(function()
                local selection = action_state.get_selected_entry()
                actions.close(prompt_bufnr)
                if not selection then
                    return
                end
                local path = selection.value
                vim.cmd("cd " .. vim.fn.fnameescape(path))
                vim.notify("Switched to " .. path, vim.log.levels.INFO)

                -- Dismiss the Alpha home screen if open in any window
                for _, win in ipairs(vim.api.nvim_list_wins()) do
                    local buf = vim.api.nvim_win_get_buf(win)
                    if vim.bo[buf].filetype == "alpha" then
                        vim.api.nvim_win_call(win, function()
                            vim.cmd("enew")
                        end)
                    end
                end

                -- Open and focus NvimTree directly at the bookmarked folder
                local ok_tree, api = pcall(require, "nvim-tree.api")
                if ok_tree then
                    api.tree.open({ path = path })
                end
            end)

            -- Delete bookmark on <C-d>
            local function delete_bookmark()
                local selection = action_state.get_selected_entry()
                if not selection then
                    return
                end
                local to_delete = selection.value
                local current_list = load_bookmarks()
                local new_list = {}
                for _, b in ipairs(current_list) do
                    if b ~= to_delete then
                        table.insert(new_list, b)
                    end
                end
                save_bookmarks(new_list)
                bookmarks = new_list
                action_state.get_current_picker(prompt_bufnr):refresh(make_finder(), { reset_prompt = false })
                vim.notify("Removed bookmark: " .. to_delete, vim.log.levels.INFO)
            end

            map("i", "<C-d>", delete_bookmark)
            map("n", "<C-d>", delete_bookmark)
            map("n", "dd", delete_bookmark)

            return true
        end,
    })

    pickers.new({}, opts):find()
end

-- Commands
vim.api.nvim_create_user_command("BookmarkFolder", function(opts)
    M.add_bookmark(opts.args)
end, { nargs = "?" })

vim.api.nvim_create_user_command("BookmarkFoldersOpen", function()
    M.open_picker()
end, {})

-- Keybindings
vim.keymap.set("n", "<leader>bm", function()
    M.add_bookmark()
end, { desc = "[B]ookmark Current [M]enu/Folder" })

vim.keymap.set("n", "<leader>fp", function()
    M.open_picker()
end, { desc = "[F]ind [P]roject / Bookmarked Folders" })

return M
