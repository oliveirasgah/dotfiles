-- Disable unused built-in plugins
vim.g.loaded_gzip = 1
vim.g.loaded_matchit = 1
vim.g.loaded_matchparen = 1
vim.g.loaded_netrwPlugin = 1
vim.g.loaded_tarPlugin = 1
vim.g.loaded_tohtml = 1
vim.g.loaded_tutor = 1
vim.g.loaded_zipPlugin = 1

require("config.options")

-- Install plugins and update the runtimepath via vim.pack
require("config.pack")

-- Enable bytecode caching AFTER vim.pack has added plugins to the runtimepath
vim.loader.enable()

-- On first run, vim.pack downloads plugins asynchronously.
-- They won't be available until the next restart.
if not pcall(require, "catppuccin") then
  vim.schedule(function()
    vim.notify("First run: plugins are being installed — please restart Neovim when complete.", vim.log.levels.WARN)
  end)
  return
end

-- Plugin setup (order matters for dependencies)
require("plugins.colorscheme")
require("plugins.ui")
require("plugins.editor")
require("plugins.treesitter")
require("plugins.telescope")
require("plugins.completion")
require("plugins.lsp")
require("plugins.formatting")
require("plugins.dap")
require("plugins.repl")
require("plugins.lang.rust")
require("plugins.lang.database")
require("plugins.lang.python")

-- Keymaps and autocmds last
require("config.autocmds")
require("config.keymaps")
