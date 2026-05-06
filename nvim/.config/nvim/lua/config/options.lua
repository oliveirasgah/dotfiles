vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- vim-dadbod-ui
vim.g.db_ui_use_nerd_fonts = 1

local opt = vim.opt

opt.backup = false
opt.clipboard = "unnamedplus"
opt.cmdheight = 1
opt.completeopt = { "menuone", "noselect" }
opt.conceallevel = 0
opt.confirm = true
opt.cursorline = true
opt.expandtab = true
opt.fileencoding = "utf-8"
opt.guifont = "monospace:h17"
opt.hlsearch = false
opt.ignorecase = true
opt.incsearch = true
opt.linebreak = true
opt.mouse = ""
opt.number = true
opt.numberwidth = 2
opt.pumheight = 10
opt.relativenumber = true
opt.scrolloff = 8
opt.shiftwidth = 2
opt.showmode = false
opt.sidescrolloff = 8
opt.signcolumn = "yes"
opt.smartcase = true
opt.smartindent = true
opt.softtabstop = 2
opt.splitbelow = true
opt.splitright = true
opt.swapfile = false
opt.tabstop = 2
opt.termguicolors = true
opt.timeoutlen = 500
opt.undofile = true
opt.updatetime = 100
opt.whichwrap = "bs<>[]hl"
opt.wrap = false
opt.writebackup = false

opt.shortmess:append({ W = true, I = true, c = true, C = true })
