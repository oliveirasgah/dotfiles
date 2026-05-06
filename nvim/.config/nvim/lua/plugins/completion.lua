require("blink.cmp").setup({
  keymap = {
    preset = "default",
    ["<Tab>"] = { "select_next", "snippet_forward", "fallback" },
    ["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
    ["<CR>"] = { "accept", "fallback" },
    ["<C-Space>"] = { "show", "show_documentation", "hide_documentation" },
    ["<C-e>"] = { "hide" },
    ["<C-k>"] = { "show_documentation", "hide_documentation" },
  },
  appearance = {
    nerd_font_variant = "mono",
  },
  completion = {
    accept = { auto_brackets = { enabled = true } },
    documentation = {
      auto_show = true,
      auto_show_delay_ms = 200,
      window = { border = "rounded" },
    },
    menu = {
      border = "rounded",
      draw = { treesitter = { "lsp" } },
    },
  },
  sources = {
    default = { "lsp", "path", "snippets", "buffer", "dadbod" },
    providers = {
      -- vim-dadbod-completion source for SQL buffers
      dadbod = { name = "Dadbod", module = "vim_dadbod_completion.blink" },
    },
  },
  signature = {
    enabled = true,
    window = { border = "rounded" },
  },
})
