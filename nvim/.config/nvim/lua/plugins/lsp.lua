-- diagnostic display
vim.diagnostic.config({
  virtual_text = false,
  update_in_insert = false,
  underline = true,
  severity_sort = true,
  float = {
    focusable = true,
    style = "minimal",
    border = "rounded",
    source = true,
    header = "",
    prefix = "",
  },
})

-- capabilities merged with blink.cmp
local capabilities =
  vim.tbl_deep_extend("force", vim.lsp.protocol.make_client_capabilities(), require("blink.cmp").get_lsp_capabilities())

-- lazydev: better Neovim Lua development
require("lazydev").setup({
  library = {
    { path = "${3rd}/luv/library", words = { "vim%.uv" } },
  },
})

-- per-server configs
vim.lsp.config("lua_ls", {
  capabilities = capabilities,
  settings = {
    Lua = {
      diagnostics = { globals = { "vim" } },
      workspace = { checkThirdParty = false },
    },
  },
})

vim.lsp.config("emmet_ls", {
  capabilities = capabilities,
  filetypes = {
    "css",
    "eruby",
    "html",
    "javascript",
    "javascriptreact",
    "less",
    "sass",
    "scss",
    "svelte",
    "typescriptreact",
    "vue",
  },
})

vim.lsp.config("jsonls", {
  capabilities = capabilities,
  settings = {
    json = {
      schemas = require("schemastore").json.schemas(),
      validate = { enable = true },
    },
  },
})

-- default capabilities for remaining servers
local servers = { "cssls", "html", "htmx", "pyright", "ts_ls", "ruby_lsp", "sqlls" }
for _, server in ipairs(servers) do
  vim.lsp.config(server, { capabilities = capabilities })
end

-- mason
require("mason").setup({
  ui = {
    border = "rounded",
    icons = { package_installed = "✓", package_pending = "➜", package_uninstalled = "✗" },
  },
  ensure_installed = { "dart-debug-adapter", "debugpy" },
})

-- mason-lspconfig: rust_analyzer excluded (handled by rustaceanvim)
require("mason-lspconfig").setup({
  ensure_installed = {
    "cssls",
    "emmet_ls",
    "html",
    "htmx",
    "jsonls",
    "lua_ls",
    "pyright",
    "ruby_lsp",
    "sqlls",
    "ts_ls",
  },
  automatic_installation = true,
})
