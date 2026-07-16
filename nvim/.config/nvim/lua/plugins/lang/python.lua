-- venv-selector: manage Python virtual environments.
-- Auto-activation is handled by venv-selector's own autocmds (buffer-local
-- restore, persistent cache restore, and uv detection) registered in setup(),
-- so no manual cache retrieval is needed.
require("venv-selector").setup()
