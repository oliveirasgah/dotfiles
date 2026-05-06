-- rustaceanvim manages rust-analyzer directly; do NOT add rust_analyzer to mason-lspconfig
vim.g.rustaceanvim = {
  server = {
    capabilities = vim.tbl_deep_extend(
      "force",
      vim.lsp.protocol.make_client_capabilities(),
      require("blink.cmp").get_lsp_capabilities()
    ),
  },
}

-- crates.nvim: Cargo.toml helper
require("crates").setup({
  lsp = {
    enabled = true,
    actions = true,
    completion = true,
    hover = true,
  },
})
