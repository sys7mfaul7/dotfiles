-- Finder: fzf-lua pickers under <leader>s ("search"); <leader>f stays Format
local ok, fz = pcall(require, "fzf-lua")
if not ok then return end
local map = vim.keymap.set
local function m(lhs, fn, desc) map("n", lhs, function() fz[fn]() end, { desc = desc }) end
m("<leader>sf", "files", "Files")
m("<leader>sg", "live_grep", "Live grep")
m("<leader>sw", "grep_cword", "Grep word under cursor")
map("x", "<leader>sw", function() fz.grep_visual() end, { desc = "Grep selection" })
m("<leader>sb", "buffers", "Buffers")
m("<leader>sr", "oldfiles", "Recent files")
m("<leader>sh", "helptags", "Help tags")
m("<leader>sk", "keymaps", "Keymaps")
m("<leader>sc", "commands", "Commands")
m("<leader>sd", "diagnostics_document", "Diagnostics (buffer)")
m("<leader>sD", "diagnostics_workspace", "Diagnostics (workspace)")
m("<leader>ss", "lsp_document_symbols", "LSP document symbols")
m("<leader>s/", "blines", "Lines in buffer")
m("<leader>s.", "resume", "Resume last search")
m("<leader><leader>", "buffers", "Buffers")
local okw, wk = pcall(require, "which-key")
if okw then wk.add({ { "<leader>s", group = "Search (fzf)" } }) end
