-- diagnostic signs (used by neo-tree and LSP)
vim.fn.sign_define("DiagnosticSignError", { text = " ", texthl = "DiagnosticSignError" })
vim.fn.sign_define("DiagnosticSignWarn", { text = " ", texthl = "DiagnosticSignWarn" })
vim.fn.sign_define("DiagnosticSignInfo", { text = " ", texthl = "DiagnosticSignInfo" })
vim.fn.sign_define("DiagnosticSignHint", { text = "󰌵", texthl = "DiagnosticSignHint" })

-- neo-tree
require("neo-tree").setup({
  close_if_last_window = false,
  popup_border_style = "rounded",
  enable_git_status = true,
  enable_diagnostics = true,
  open_files_do_not_replace_types = { "terminal", "trouble", "qf" },
  default_component_configs = {
    indent = {
      indent_size = 2,
      padding = 1,
      with_markers = true,
      indent_marker = "│",
      last_indent_marker = "└",
      with_expanders = true,
      expander_collapsed = "",
      expander_expanded = "",
    },
    icon = {
      folder_closed = "󰐋",
      folder_open = "󰝠",
      folder_empty = "󰜌",
    },
    modified = { symbol = "[+]" },
    git_status = {
      symbols = {
        added = "✚",
        modified = "✹",
        deleted = "✖",
        renamed = "➜",
        untracked = "★",
        ignored = "◌",
        unstaged = "✗",
        staged = "✓",
        conflict = "⚑",
      },
    },
  },
  window = {
    position = "left",
    width = 40,
    mappings = {
      ["<cr>"] = "open",
      ["P"] = { "toggle_preview", config = { use_float = true } },
      ["l"] = "focus_preview",
      ["S"] = "open_split",
      ["s"] = "open_vsplit",
      ["t"] = "open_tabnew",
      ["C"] = "close_node",
      ["z"] = "close_all_nodes",
      ["a"] = { "add", config = { show_path = "none" } },
      ["A"] = "add_directory",
      ["d"] = "delete",
      ["r"] = "rename",
      ["y"] = "copy_to_clipboard",
      ["x"] = "cut_to_clipboard",
      ["p"] = "paste_from_clipboard",
      ["q"] = "close_window",
      ["R"] = "refresh",
      ["?"] = "show_help",
    },
  },
  filesystem = {
    filtered_items = {
      visible = false,
      hide_dotfiles = true,
      hide_gitignored = true,
      never_show_by_pattern = { "*~" },
    },
    follow_current_file = { enabled = false },
    hijack_netrw_behavior = "open_default",
    window = {
      mappings = {
        ["<bs>"] = "navigate_up",
        ["."] = "set_root",
        ["H"] = "toggle_hidden",
        ["/"] = "fuzzy_finder",
        ["f"] = "filter_on_submit",
        ["<c-x>"] = "clear_filter",
        ["[g"] = "prev_git_modified",
        ["]g"] = "next_git_modified",
      },
    },
  },
})

-- gitsigns
require("gitsigns").setup({
  signs = {
    add = { text = "│" },
    change = { text = "│" },
    delete = { text = "_" },
    topdelete = { text = "‾" },
    changedelete = { text = "~" },
    untracked = { text = "┆" },
  },
  current_line_blame = false,
  current_line_blame_opts = {
    virt_text = true,
    virt_text_pos = "eol",
    delay = 1000,
  },
  current_line_blame_formatter = "<author>, <author_time:%Y-%m-%d> - <summary>",
  preview_config = { border = "single", style = "minimal", relative = "cursor", row = 1, col = 1 },
})

-- mini.ai: extended text objects
require("mini.ai").setup({ n_lines = 500 })

-- mini.pairs: auto-pairs
require("mini.pairs").setup()

-- flash: fast navigation
require("flash").setup({
  modes = { char = { jump_labels = true } },
})

-- todo-comments
require("todo-comments").setup()

-- trouble v3
require("trouble").setup({
  modes = {
    lsp = { win = { position = "right" } },
  },
})

-- grug-far: find and replace
require("grug-far").setup({ headerMaxWidth = 80 })

-- persistence: session management
require("persistence").setup({
  dir = vim.fn.stdpath("state") .. "/sessions/",
})

-- ts-comments: treesitter-aware commenting (replaces Comment.nvim)
require("ts-comments").setup()
