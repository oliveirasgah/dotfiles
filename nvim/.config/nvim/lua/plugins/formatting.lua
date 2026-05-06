-- conform: formatters
require("conform").setup({
  formatters = {
    sql_formatter = {
      command = "sql-formatter",
      args = {
        "--language",
        "postgresql",
        "--config",
        '{"keywordCase":"upper","dataTypeCase":"upper","functionCase":"upper","tabWidth":2}',
      },
    },
  },
  formatters_by_ft = {
    css = { "prettier" },
    html = { "prettier" },
    javascript = { "prettier" },
    json = { "prettier" },
    lua = { "stylua" },
    markdown = { "prettier" },
    python = { "ruff_format" },
    ruby = { "rubocop" },
    sql = { "sql_formatter" },
    typescript = { "prettier" },
    yaml = { "prettier" },
  },
})

-- nvim-lint: linters triggered via autocmd in config/autocmds.lua
require("lint").linters_by_ft = {
  javascript = { "eslint_d" },
  typescript = { "eslint_d" },
  python = { "ruff" },
  ruby = { "rubocop" },
}

-- trigger linting on save and when leaving insert mode
vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
  callback = function()
    require("lint").try_lint()
  end,
})
