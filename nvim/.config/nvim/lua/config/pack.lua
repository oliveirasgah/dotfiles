-- Build hooks must be registered BEFORE vim.pack.add()
vim.api.nvim_create_autocmd("PackChanged", {
  callback = function(ev)
    local name = ev.data.spec.name
    local kind = ev.data.kind
    if name == "telescope-fzf-native.nvim" and (kind == "install" or kind == "update") then
      vim.system({ "make" }, { cwd = ev.data.path }):wait()
    end
  end,
})

local gh = function(repo)
  return "https://github.com/" .. repo
end

vim.pack.add({
  -- Core dependencies
  gh("nvim-lua/plenary.nvim"),
  gh("MunifTanjim/nui.nvim"),

  -- Colorscheme
  { src = gh("catppuccin/nvim"), name = "catppuccin" },

  -- UI
  -- nvim-notify removed: snacks.notifier replaces it
  -- dressing.nvim removed: archived; snacks.input + telescope-ui-select replace it
  gh("folke/noice.nvim"),
  gh("nvim-lualine/lualine.nvim"),
  gh("akinsho/bufferline.nvim"),
  gh("folke/which-key.nvim"),
  gh("folke/snacks.nvim"), -- notifier, input, bigfile, indent, words, statuscolumn

  -- Editor
  gh("nvim-neo-tree/neo-tree.nvim"),
  gh("lewis6991/gitsigns.nvim"),
  gh("echasnovski/mini.nvim"), -- mini.ai, mini.pairs, mini.icons (replaces nvim-web-devicons)
  gh("folke/flash.nvim"),
  gh("folke/todo-comments.nvim"),
  gh("folke/trouble.nvim"),
  gh("MagicDuck/grug-far.nvim"),
  gh("folke/persistence.nvim"),
  gh("folke/ts-comments.nvim"), -- replaces Comment.nvim + nvim-ts-context-commentstring

  -- Treesitter
  gh("nvim-treesitter/nvim-treesitter"),
  gh("nvim-treesitter/nvim-treesitter-textobjects"),
  gh("windwp/nvim-ts-autotag"),

  -- Telescope
  gh("nvim-telescope/telescope.nvim"),
  { src = gh("nvim-telescope/telescope-fzf-native.nvim"), name = "telescope-fzf-native.nvim" },
  gh("nvim-telescope/telescope-ui-select.nvim"), -- replaces dressing for vim.ui.select

  -- LSP
  gh("neovim/nvim-lspconfig"),
  gh("mason-org/mason.nvim"),
  gh("mason-org/mason-lspconfig.nvim"),
  gh("folke/lazydev.nvim"),
  gh("b0o/SchemaStore.nvim"),

  -- Completion
  gh("saghen/blink.cmp"),
  gh("rafamadriz/friendly-snippets"),

  -- Formatting & Linting
  gh("stevearc/conform.nvim"),
  gh("mfussenegger/nvim-lint"),

  -- DAP
  gh("mfussenegger/nvim-dap"),
  gh("nvim-neotest/nvim-nio"),
  gh("rcarriga/nvim-dap-ui"),
  gh("mfussenegger/nvim-dap-python"),
  gh("suketa/nvim-dap-ruby"),

  -- REPL
  gh("Vigemus/iron.nvim"),
  gh("goerz/jupytext.nvim"),

  -- Rust
  gh("mrcjkb/rustaceanvim"),
  gh("saecki/crates.nvim"),

  -- Database
  gh("tpope/vim-dadbod"),
  gh("kristijanhusak/vim-dadbod-ui"),
  gh("kristijanhusak/vim-dadbod-completion"),

  -- Python
  gh("linux-cultist/venv-selector.nvim"),
})
