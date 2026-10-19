return {
  "jake-stewart/multicursor.nvim",
  branch = "1.0",
  event = "VeryLazy",
  config = function()
    local mc = require("multicursor-nvim")
    mc.setup()

    local set = vim.keymap.set

    -- Add or skip cursor above/below the main cursor
    set({ "n", "x" }, "<up>", function()
      mc.lineAddCursor(-1)
    end, { desc = "MultiCursor: Add cursor above" })
    set({ "n", "x" }, "<down>", function()
      mc.lineAddCursor(1)
    end, { desc = "MultiCursor: Add cursor below" })
    set({ "n", "x" }, "<S-up>", function()
      mc.lineSkipCursor(-1)
    end, { desc = "MultiCursor: Skip cursor above" })
    set({ "n", "x" }, "<S-down>", function()
      mc.lineSkipCursor(1)
    end, { desc = "MultiCursor: Skip cursor below" })
    set({ "n", "x" }, "<C-up>", function()
      mc.lineSkipCursor(-1)
    end, { desc = "MultiCursor: Skip cursor above" })
    set({ "n", "x" }, "<C-down>", function()
      mc.lineSkipCursor(1)
    end, { desc = "MultiCursor: Skip cursor below" })
    set({ "n", "x" }, "<leader><up>", function()
      mc.lineSkipCursor(-1)
    end, { desc = "MultiCursor: Skip cursor above" })
    set({ "n", "x" }, "<leader><down>", function()
      mc.lineSkipCursor(1)
    end, { desc = "MultiCursor: Skip cursor below" })

    -- Add or skip adding a new cursor by matching word/selection
    -- Also map <C-n> (VSCode / vim-visual-multi style) alongside <leader>n / <leader>s
    set({ "n", "x" }, "<C-n>", function()
      mc.matchAddCursor(1)
    end, { desc = "MultiCursor: Add cursor at next match" })
    set({ "n", "x" }, "<leader>n", function()
      mc.matchAddCursor(1)
    end, { desc = "MultiCursor: [N]ext match add cursor" })
    set({ "n", "x" }, "<leader>N", function()
      mc.matchAddCursor(-1)
    end, { desc = "MultiCursor: Prev match add cursor" })
    set({ "n", "x" }, "<leader>s", function()
      mc.matchSkipCursor(1)
    end, { desc = "MultiCursor: [S]kip next match" })
    set({ "n", "x" }, "<leader>S", function()
      mc.matchSkipCursor(-1)
    end, { desc = "MultiCursor: Skip prev match" })

    -- Add a cursor for all matches of cursor word/selection in the document
    set({ "n", "x" }, "<leader>M", mc.matchAllAddCursors, { desc = "MultiCursor: [M]atch all occurrences" })

    -- Add and remove cursors with control + left click
    set("n", "<c-leftmouse>", mc.handleMouse, { desc = "MultiCursor: Toggle cursor with mouse" })
    set("n", "<c-leftdrag>", mc.handleMouseDrag, { desc = "MultiCursor: Drag cursor with mouse" })
    set("n", "<c-leftrelease>", mc.handleMouseRelease, { desc = "MultiCursor: Release mouse drag" })

    -- Disable and enable cursors
    set({ "n", "x" }, "<c-q>", mc.toggleCursor, { desc = "MultiCursor: Toggle cursor" })

    -- Visual mode utilities (only apply in visual mode)
    set("x", "I", mc.insertVisual, { desc = "MultiCursor: Insert at start of visual lines" })
    set("x", "A", mc.appendVisual, { desc = "MultiCursor: Append at end of visual lines" })
    set("x", "M", mc.matchCursors, { desc = "MultiCursor: Match regex within selection" })
    set("x", "S", mc.splitCursors, { desc = "MultiCursor: Split selection by regex" })

    -- Restore accidentally cleared cursors
    set("n", "<leader>gv", mc.restoreCursors, { desc = "MultiCursor: Restore cleared cursors" })

    -- Mappings defined in a keymap layer only apply when there are
    -- multiple cursors. This lets you have overlapping mappings safely!
    mc.addKeymapLayer(function(layerSet)
      -- Select a different cursor as the main one
      layerSet({ "n", "x" }, "<left>", mc.prevCursor)
      layerSet({ "n", "x" }, "<right>", mc.nextCursor)

      -- Delete the main cursor
      layerSet({ "n", "x" }, "<leader>x", mc.deleteCursor)

      -- Align cursor columns (only active when multiple cursors exist, so <leader>ag works normally otherwise)
      layerSet("n", "<leader>a", mc.alignCursors)

      -- Enable and clear cursors using escape (falls back to :nohlsearch when single cursor)
      layerSet("n", "<esc>", function()
        if not mc.cursorsEnabled() then
          mc.enableCursors()
        else
          mc.clearCursors()
        end
      end)
    end)

    -- Customize how cursors look
    local hl = vim.api.nvim_set_hl
    hl(0, "MultiCursorCursor", { reverse = true })
    hl(0, "MultiCursorVisual", { link = "Visual" })
    hl(0, "MultiCursorSign", { link = "SignColumn" })
    hl(0, "MultiCursorMatchPreview", { link = "Search" })
    hl(0, "MultiCursorDisabledCursor", { reverse = true })
    hl(0, "MultiCursorDisabledVisual", { link = "Visual" })
    hl(0, "MultiCursorDisabledSign", { link = "SignColumn" })
  end,
}
