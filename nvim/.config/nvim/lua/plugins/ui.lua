-- mini.icons replaces nvim-web-devicons; must run before other plugins reference icons
require("mini.icons").setup()
require("mini.icons").mock_nvim_web_devicons()

-- noice: replaces cmdline, search, and LSP message UI
-- snacks.notifier handles vim.notify, so noice's notify view is disabled
require("noice").setup({
  lsp = {
    override = {
      ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
      ["vim.lsp.util.stylize_markdown"] = true,
    },
  },
  presets = {
    bottom_search = false,
    command_palette = true,
    long_message_to_split = true,
    lsp_doc_border = true,
  },
  routes = {
    -- send vim.notify calls to snacks.notifier instead
    { filter = { event = "notify" }, opts = { skip = true } },
  },
})

-- snacks: bigfile, indent guides, word highlights, input UI, notifications
require("snacks").setup({
  bigfile = { enabled = true },
  indent = { enabled = true },
  input = { enabled = true },
  notifier = { enabled = true, timeout = 3000 },
  statuscolumn = { enabled = true },
  words = { enabled = true },
  dashboard = { enabled = false },
  picker = { enabled = false },
  scroll = { enabled = false },
  zen = { enabled = false },
})

-- lualine
require("lualine").setup({
  options = {
    theme = "catppuccin",
    globalstatus = true,
    disabled_filetypes = { statusline = { "dashboard", "alpha" } },
  },
  sections = {
    lualine_a = { "mode" },
    lualine_b = { "branch", "diff", "diagnostics" },
    lualine_c = { { "filename", path = 1 } },
    lualine_x = {
      {
        function()
          return require("noice").api.status.command.get()
        end,
        cond = function()
          return package.loaded["noice"] and require("noice").api.status.command.has()
        end,
        color = { fg = "#ff9e64" },
      },
      "encoding",
      "fileformat",
      "filetype",
    },
    lualine_y = { "progress" },
    lualine_z = { "location" },
  },
})

-- bufferline
require("bufferline").setup({
  options = {
    separator_style = "slope",
    always_show_bufferline = false,
    offsets = {
      {
        filetype = "neo-tree",
        text = "Explorer",
        separator = true,
        text_align = "center",
        highlight = "Directory",
      },
    },
  },
})

-- which-key
require("which-key").setup({
  preset = "modern",
  delay = 500,
  icons = { mappings = true },
})
