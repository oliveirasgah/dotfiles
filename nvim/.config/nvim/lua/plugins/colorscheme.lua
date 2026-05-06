require("catppuccin").setup({
  flavour = "mocha",
  background = { light = "latte", dark = "mocha" },
  transparent_background = false,
  term_colors = true,
  integrations = {
    blink_cmp = true,
    bufferline = true,
    flash = true,
    gitsigns = true,
    mason = true,
    neo_tree = true,
    noice = true,
    snacks = true,
    telescope = { enabled = true },
    treesitter = true,
    trouble = true,
    which_key = true,
  },
})

vim.cmd.colorscheme("catppuccin")
