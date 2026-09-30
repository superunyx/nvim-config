return {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    config = function()
        -- In nvim 0.12+, treesitter highlighting is built-in.
        -- nvim-treesitter manages parser installations.
        local ok_ts, ts = pcall(require, "nvim-treesitter")
        if ok_ts and ts.setup then
            pcall(ts.setup, {})
        end
    end,
}
