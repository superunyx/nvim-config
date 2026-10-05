return {
  "willothy/flatten.nvim",
  lazy = false,
  priority = 1001,
  opts = function()
    return {
      window = {
        open = "smart",
        focus = "first",
      },
      hooks = {
        should_block = function(argv)
          return vim.tbl_contains(argv, "-b")
        end,
        pre_open = function()
          local ok, floaterminal = pcall(require, "config.floaterminal")
          if ok and floaterminal.is_open and floaterminal.is_open() then
            floaterminal.hide()
          end
        end,
        post_open = function(opts, winnr_arg, ft_arg, is_blocking_arg)
          local bufnr = type(opts) == "table" and opts.bufnr or opts
          local winnr = type(opts) == "table" and opts.winnr or winnr_arg
          local ft = type(opts) == "table" and opts.filetype or ft_arg
          local is_blocking = type(opts) == "table" and opts.is_blocking or is_blocking_arg

          local ok, floaterminal = pcall(require, "config.floaterminal")
          if ok and floaterminal.is_open and floaterminal.is_open() then
            floaterminal.hide()
          end

          if winnr and vim.api.nvim_win_is_valid(winnr) then
            vim.api.nvim_set_current_win(winnr)
          end

          if ft == "gitcommit" or ft == "gitrebase" then
            vim.api.nvim_create_autocmd("BufWritePost", {
              buffer = bufnr,
              once = true,
              callback = vim.schedule_wrap(function()
                pcall(vim.api.nvim_buf_delete, bufnr, {})
              end),
            })
          end
        end,
        no_files = function()
          local ok, floaterminal = pcall(require, "config.floaterminal")
          if ok and floaterminal.is_open and floaterminal.is_open() then
            floaterminal.hide()
          end
          return false
        end,
        block_end = function()
          vim.schedule(function()
            local ok, floaterminal = pcall(require, "config.floaterminal")
            if ok and floaterminal.show then
              floaterminal.show()
            end
          end)
        end,
      },
    }
  end,
}
