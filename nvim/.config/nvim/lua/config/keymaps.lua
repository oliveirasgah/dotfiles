local map = vim.keymap.set

-- General

map("i", "jk", "<Esc>", { desc = "Exit insert mode" })
map("i", "kj", "<Esc>", { desc = "Exit insert mode" })
map("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })
map({ "i", "x", "n", "s" }, "<C-s>", "<cmd>w<CR><Esc>", { desc = "Save file" })
map("n", "<leader>qq", "<cmd>confirm qall<CR>", { desc = "Quit all" })

-- Windows

map("n", "<C-h>", "<C-w>h", { desc = "Go to left window" })
map("n", "<C-j>", "<C-w>j", { desc = "Go to lower window" })
map("n", "<C-k>", "<C-w>k", { desc = "Go to upper window" })
map("n", "<C-l>", "<C-w>l", { desc = "Go to right window" })
map("n", "<C-Up>", "<cmd>resize -2<CR>", { desc = "Decrease window height" })
map("n", "<C-Down>", "<cmd>resize +2<CR>", { desc = "Increase window height" })
map("n", "<C-Left>", "<cmd>vertical resize -2<CR>", { desc = "Decrease window width" })
map("n", "<C-Right>", "<cmd>vertical resize +2<CR>", { desc = "Increase window width" })
map("n", "<leader>wv", "<C-w>v", { desc = "Split vertically" })
map("n", "<leader>wh", "<C-w>s", { desc = "Split horizontally" })
map("n", "<leader>wd", "<cmd>close<CR>", { desc = "Close window" })

-- Buffers

map("n", "<S-l>", "<cmd>bnext<CR>", { desc = "Next buffer" })
map("n", "<S-h>", "<cmd>bprevious<CR>", { desc = "Previous buffer" })
map("n", "<leader>bd", "<cmd>bdelete<CR>", { desc = "Delete buffer" })
map("n", "<leader>bD", "<cmd>bdelete!<CR>", { desc = "Delete buffer (force)" })

-- Editing

-- Center search results
map("n", "n", "nzzzv", { desc = "Next result (centered)" })
map("n", "N", "Nzzzv", { desc = "Prev result (centered)" })

-- Paste without overwriting register
map("x", "<leader>p", '"_dP', { desc = "Paste without yanking" })

-- Delete without yanking
map({ "n", "v" }, "<leader>D", '"_d', { desc = "Delete without yanking" })

-- Toggle comments
map("n", "<C-/>", "gcc", { desc = "Toggle comment", remap = true })
map("v", "<C-/>", "gc", { desc = "Toggle comment", remap = true })

-- Move lines in normal mode
map("n", "<A-j>", ":m .+1<CR>==", { desc = "Move line down" })
map("n", "<A-k>", ":m .-2<CR>==", { desc = "Move line up" })

-- Move lines in visual mode
map("v", "<A-j>", ":m .+1<CR>==", { desc = "Move line down" })
map("v", "<A-k>", ":m .-2<CR>==", { desc = "Move line up" })

-- Stay in indent mode
map("v", "<", "<gv", { desc = "Indent left" })
map("v", ">", ">gv", { desc = "Indent right" })

-- File explorer

map("n", "<leader>e", "<cmd>Neotree toggle<CR>", { desc = "Toggle explorer" })
map("n", "<leader>E", "<cmd>Neotree reveal<CR>", { desc = "Reveal file in explorer" })

-- Telescope

map("n", "<leader>ff", function()
  require("telescope.builtin").find_files(require("telescope.themes").get_dropdown({ previewer = false }))
end, { desc = "Find files" })

map("n", "<leader>fv", function()
  require("telescope.builtin").git_files(require("telescope.themes").get_dropdown({ previewer = false }))
end, { desc = "Find git files" })

map("n", "<leader>fh", function()
  require("telescope.builtin").find_files(
    require("telescope.themes").get_dropdown({ previewer = false, hidden = true })
  )
end, { desc = "Find hidden files" })

map("n", "<leader>fg", "<cmd>Telescope live_grep<CR>", { desc = "Live grep" })
map("n", "<leader>fb", "<cmd>Telescope buffers<CR>", { desc = "Find buffers" })
map("n", "<leader>fk", "<cmd>Telescope keymaps<CR>", { desc = "Find keymaps" })
map("n", "<leader>fr", "<cmd>Telescope oldfiles<CR>", { desc = "Recent files" })
map("n", "<leader>fc", "<cmd>Telescope commands<CR>", { desc = "Find commands" })
map("n", "<leader>ft", "<cmd>TodoTelescope<CR>", { desc = "Todo comments" })
map("n", "<leader>f/", "<cmd>Telescope current_buffer_fuzzy_find<CR>", { desc = "Fuzzy find in buffer" })

-- Git

map("n", "<leader>vb", "<cmd>Gitsigns blame_line<CR>", { desc = "Blame line" })
map("n", "<leader>vp", "<cmd>Gitsigns preview_hunk<CR>", { desc = "Preview hunk" })
map("n", "<leader>vs", "<cmd>Gitsigns stage_hunk<CR>", { desc = "Stage hunk" })
map("n", "<leader>vu", "<cmd>Gitsigns undo_stage_hunk<CR>", { desc = "Undo stage hunk" })
map("n", "<leader>vr", "<cmd>Gitsigns reset_hunk<CR>", { desc = "Reset hunk" })
map("n", "<leader>vS", "<cmd>Gitsigns stage_buffer<CR>", { desc = "Stage buffer" })
map("n", "<leader>vR", "<cmd>Gitsigns reset_buffer<CR>", { desc = "Reset buffer" })
map("n", "<leader>vd", "<cmd>Gitsigns diffthis<CR>", { desc = "Diff this" })
map("n", "]h", "<cmd>Gitsigns next_hunk<CR>", { desc = "Next hunk" })
map("n", "[h", "<cmd>Gitsigns prev_hunk<CR>", { desc = "Previous hunk" })

-- LSP

map("n", "gD", vim.lsp.buf.declaration, { desc = "Go to declaration" })
map("n", "gd", vim.lsp.buf.definition, { desc = "Go to definition" })
map("n", "gI", vim.lsp.buf.implementation, { desc = "Go to implementation" })
map("n", "gr", vim.lsp.buf.references, { desc = "References" })
map("n", "K", vim.lsp.buf.hover, { desc = "Hover docs" })
map("n", "gl", vim.diagnostic.open_float, { desc = "Diagnostic float" })
map("n", "<leader>la", vim.lsp.buf.code_action, { desc = "Code actions" })
map("n", "<leader>lr", vim.lsp.buf.rename, { desc = "Rename symbol" })
map("n", "<leader>ls", vim.lsp.buf.signature_help, { desc = "Signature help" })
map("n", "<leader>lq", vim.diagnostic.setloclist, { desc = "Diagnostics → loclist" })
map("n", "<leader>li", "<cmd>LspInfo<CR>", { desc = "LSP info" })
map("n", "]d", function()
  vim.diagnostic.goto_next()
end, { desc = "Next diagnostic" })
map("n", "[d", function()
  vim.diagnostic.goto_prev()
end, { desc = "Previous diagnostic" })

-- Formatting

map({ "n", "v" }, "<leader>cf", function()
  require("conform").format({ lsp_fallback = true, async = false, timeout_ms = 500 })
end, { desc = "Format file / selection" })

-- Diagnostics

map("n", "<leader>xx", "<cmd>Trouble diagnostics toggle<CR>", { desc = "Diagnostics" })
map("n", "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<CR>", { desc = "Buffer diagnostics" })
map("n", "<leader>xs", "<cmd>Trouble symbols toggle focus=false<CR>", { desc = "Symbols" })
map("n", "<leader>xl", "<cmd>Trouble lsp toggle focus=false win.position=right<CR>", { desc = "LSP refs / defs" })
map("n", "<leader>xL", "<cmd>Trouble loclist toggle<CR>", { desc = "Location list" })
map("n", "<leader>xQ", "<cmd>Trouble qflist toggle<CR>", { desc = "Quickfix list" })

-- Motion

map({ "n", "x", "o" }, "s", function()
  require("flash").jump()
end, { desc = "Flash jump" })
map({ "n", "x", "o" }, "S", function()
  require("flash").treesitter()
end, { desc = "Flash treesitter" })
map("o", "r", function()
  require("flash").remote()
end, { desc = "Flash remote" })
map({ "x", "o" }, "R", function()
  require("flash").treesitter_search()
end, { desc = "Flash treesitter search" })

-- Todo comments

map("n", "]t", function()
  require("todo-comments").jump_next()
end, { desc = "Next todo" })
map("n", "[t", function()
  require("todo-comments").jump_prev()
end, { desc = "Previous todo" })

-- Find & replace

map("n", "<leader>sr", "<cmd>GrugFar<CR>", { desc = "Search & replace" })
map("v", "<leader>sr", function()
  require("grug-far").open({ prefills = { search = vim.fn.expand("<cword>") } })
end, { desc = "Search & replace (word)" })

-- Sessions

map("n", "<leader>qs", function()
  require("persistence").load()
end, { desc = "Restore session" })
map("n", "<leader>ql", function()
  require("persistence").load({ last = true })
end, { desc = "Restore last session" })
map("n", "<leader>qd", function()
  require("persistence").stop()
end, { desc = "Don't save session" })

-- DAP

map("n", "<leader>db", "<cmd>DapToggleBreakpoint<CR>", { desc = "Toggle breakpoint" })
map("n", "<leader>dB", function()
  require("dap").set_breakpoint(vim.fn.input("Condition: "))
end, { desc = "Conditional breakpoint" })
map("n", "<leader>dc", "<cmd>DapContinue<CR>", { desc = "Continue" })
map("n", "<leader>di", "<cmd>DapStepInto<CR>", { desc = "Step into" })
map("n", "<leader>do", "<cmd>DapStepOut<CR>", { desc = "Step out" })
map("n", "<leader>dO", "<cmd>DapStepOver<CR>", { desc = "Step over" })
map("n", "<leader>dt", "<cmd>DapTerminate<CR>", { desc = "Terminate" })
map("n", "<leader>du", function()
  require("dapui").toggle()
end, { desc = "Toggle DAP UI" })
map("n", "<leader>de", function()
  require("dapui").eval()
end, { desc = "Evaluate expression" })
map("v", "<leader>de", function()
  require("dapui").eval()
end, { desc = "Evaluate selection" })

-- REPL

map("n", "<leader>rr", "<cmd>IronRepl<CR>", { desc = "Toggle REPL" })
map("n", "<leader>rR", "<cmd>IronRestart<CR>", { desc = "Restart REPL" })
map("n", "<leader>rf", "<cmd>IronFocus<CR>", { desc = "Focus REPL" })
map("n", "<leader>rh", "<cmd>IronHide<CR>", { desc = "Hide REPL" })

map("n", "<leader>sl", function()
  require("iron.core").send_line()
end, { desc = "Send line to REPL" })
map("n", "<leader>sf", function()
  require("iron.core").send_file()
end, { desc = "Send file to REPL" })
map("n", "<leader>sp", function()
  require("iron.core").send_paragraph()
end, { desc = "Send paragraph to REPL" })
map("n", "<leader>su", function()
  require("iron.core").send_until_cursor()
end, { desc = "Send until cursor" })
map("n", "<leader>sb", function()
  require("iron.core").send_code_block()
end, { desc = "Send code block" })
map("n", "<leader>sN", function()
  require("iron.core").send_code_block_and_move()
end, { desc = "Send block and move" })
map("n", "<leader>sc", function()
  require("iron.core").send_motion()
end, { desc = "Send motion to REPL" })
map("v", "<leader>sc", function()
  require("iron.core").visual_send()
end, { desc = "Send selection to REPL" })
map("n", "<leader>sq", function()
  require("iron.core").exit()
end, { desc = "Exit REPL" })
map("n", "<leader>s<Space>", function()
  require("iron.core").interrupt()
end, { desc = "Interrupt REPL" })

-- Database

map("n", "<leader>Du", "<cmd>DBUIToggle<CR>", { desc = "Toggle DB UI" })
map("n", "<leader>Df", "<cmd>DBUIFindBuffer<CR>", { desc = "Find DB buffer" })

-- Python

map("n", "<leader>cv", "<cmd>VenvSelect<CR>", { desc = "Select Python venv" })

-- Which-key groups

local ok, wk = pcall(require, "which-key")
if ok then
  wk.add({
    { "<leader>b", group = "Buffer" },
    { "<leader>c", group = "Code" },
    { "<leader>d", group = "Debug" },
    { "<leader>D", group = "Database" },
    { "<leader>e", group = "Explorer" },
    { "<leader>f", group = "Find" },
    { "<leader>l", group = "LSP" },
    { "<leader>q", group = "Session" },
    { "<leader>r", group = "REPL" },
    { "<leader>s", group = "Send" },
    { "<leader>v", group = "Git" },
    { "<leader>w", group = "Window" },
    { "<leader>x", group = "Diagnostics" },
    { "]", group = "Next" },
    { "[", group = "Previous" },
  })
end
