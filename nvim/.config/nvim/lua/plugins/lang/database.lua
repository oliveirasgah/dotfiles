-- vim-dadbod: no Lua setup required
-- vim-dadbod-ui: configured via globals in config/options.lua (db_ui_use_nerd_fonts)
-- vim-dadbod-completion: blink.cmp source registered in plugins/completion.lua

-- set omnifunc fallback for SQL buffers (used outside blink.cmp contexts)
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "sql", "mysql", "plsql" },
  callback = function()
    vim.bo.omnifunc = "vim_dadbod_completion#omni"
  end,
})
