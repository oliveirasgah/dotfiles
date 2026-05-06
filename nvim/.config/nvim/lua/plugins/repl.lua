-- iron.nvim: REPL integration
-- keymaps are defined in config/keymaps.lua
require("iron.core").setup({
  config = {
    scratch_repl = true,
    repl_definition = {
      sh = { command = { "bash" } },
      python = {
        command = { "jupyter-console", "--ZMQTerminalInteractiveShell.image_handler=None" },
        format = require("iron.fts.common").bracketed_paste_python,
        block_dividers = { "# %%", "#%%" },
      },
    },
    repl_filetype = function(_, ft)
      return ft
    end,
    repl_open_cmd = require("iron.view").bottom(40),
  },
  keymaps = {},
  highlight = { italic = true },
  ignore_blank_lines = true,
})

-- jupytext: edit Jupyter notebooks as plain text
require("jupytext").setup({
  jupytext = "jupytext",
  format = "py:percent",
  update = true,
  filetype = require("jupytext").get_filetype,
  new_template = require("jupytext").default_new_template(),
  sync_patterns = { "*.md", "*.py", "*.jl", "*.R", "*.Rmd", "*.qmd" },
  autosync = true,
  handle_url_schemes = true,
})
