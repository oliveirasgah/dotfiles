-- venv-selector: manage Python virtual environments
require("venv-selector").setup()

-- auto-activate venv when opening a project with pyproject.toml
vim.api.nvim_create_autocmd("VimEnter", {
  once = true,
  callback = function()
    if vim.fn.findfile("pyproject.toml", vim.fn.getcwd() .. ";") ~= "" then
      require("venv-selector").retrieve_from_cache()
    end
  end,
})
