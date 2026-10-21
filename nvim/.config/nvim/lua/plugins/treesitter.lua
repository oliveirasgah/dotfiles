-- nvim-treesitter (main branch): setup() only takes install_dir, so parsers,
-- highlighting, indent and textobjects are all wired up explicitly below.
local ts = require("nvim-treesitter")

ts.install({
  "bash",
  "c",
  "diff",
  "html",
  "javascript",
  "json",
  "lua",
  "luadoc",
  "markdown",
  "markdown_inline",
  "python",
  "query",
  "regex",
  "ruby",
  "rust",
  "sql",
  "toml",
  "tsx",
  "typescript",
  "vim",
  "vimdoc",
  "yaml",
})

local function attach(buf)
  if not pcall(vim.treesitter.start, buf) then
    return
  end
  vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
end

-- Start highlighting + indent per buffer, installing missing parsers on demand
-- (the old auto_install).
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("treesitter_start", { clear = true }),
  callback = function(ev)
    local lang = vim.treesitter.language.get_lang(ev.match)
    if not lang then
      return
    end
    if vim.treesitter.language.add(lang) then
      attach(ev.buf)
    elseif vim.tbl_contains(ts.get_available(), lang) then
      ts.install(lang):await(vim.schedule_wrap(function()
        if vim.api.nvim_buf_is_valid(ev.buf) then
          attach(ev.buf)
        end
      end))
    end
  end,
})

-- textobjects
require("nvim-treesitter-textobjects").setup({
  select = { lookahead = true },
  move = { set_jumps = true },
})

local select = require("nvim-treesitter-textobjects.select")
for keys, query in pairs({
  af = "@function.outer",
  ["if"] = "@function.inner",
  ac = "@class.outer",
  ic = "@class.inner",
  aa = "@parameter.outer",
  ia = "@parameter.inner",
}) do
  vim.keymap.set({ "x", "o" }, keys, function()
    select.select_textobject(query, "textobjects")
  end, { desc = "Select " .. query })
end

local move = require("nvim-treesitter-textobjects.move")
for fn, maps in pairs({
  goto_next_start = { ["]f"] = "@function.outer", ["]c"] = "@class.outer" },
  goto_next_end = { ["]F"] = "@function.outer", ["]C"] = "@class.outer" },
  goto_previous_start = { ["[f"] = "@function.outer", ["[c"] = "@class.outer" },
  goto_previous_end = { ["[F"] = "@function.outer", ["[C"] = "@class.outer" },
}) do
  for keys, query in pairs(maps) do
    vim.keymap.set({ "n", "x", "o" }, keys, function()
      move[fn](query, "textobjects")
    end, { desc = fn:gsub("_", " ") .. " " .. query })
  end
end

require("nvim-ts-autotag").setup()
