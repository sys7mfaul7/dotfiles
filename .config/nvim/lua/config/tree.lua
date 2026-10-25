-- neo-tree file browser (native vim.pack; deps: plenary, nui)
local ok, nt = pcall(require, "neo-tree")
if not ok then return end
nt.setup({
  close_if_last_window = true,
  popup_border_style = "single",
  enable_git_status = true,
  filesystem = {
    follow_current_file = { enabled = true },
    use_libuv_file_watcher = true,
    hijack_netrw_behavior = "open_current",
    filtered_items = { hide_dotfiles = false, hide_gitignored = false },
  },
  window = { width = 32 },
})
local map = vim.keymap.set
map("n", "<leader>e", "<cmd>Neotree toggle reveal left<cr>", { desc = "File tree (sidebar)" })
map("n", "<leader>E", "<cmd>Neotree reveal position=current<cr>", { desc = "Browse files (replace buffer)" })
local function hl()
  local s = vim.api.nvim_set_hl
  s(0, "NeoTreeNormal", { fg = "#c0ffc0", bg = "#000000" })
  s(0, "NeoTreeNormalNC", { fg = "#c0ffc0", bg = "#000000" })
  s(0, "NeoTreeEndOfBuffer", { fg = "#000000", bg = "#000000" })
  s(0, "NeoTreeDirectoryName", { fg = "#00ff41" })
  s(0, "NeoTreeDirectoryIcon", { fg = "#578a29" })
  s(0, "NeoTreeRootName", { fg = "#00ff41", bold = true })
  s(0, "NeoTreeFileName", { fg = "#c0ffc0" })
  s(0, "NeoTreeFileIcon", { fg = "#578a29" })
  s(0, "NeoTreeIndentMarker", { fg = "#2f5a2f" })
  s(0, "NeoTreeExpander", { fg = "#4f7f5a" })
  s(0, "NeoTreeCursorLine", { bg = "#1f6f2f" })
  s(0, "NeoTreeWinSeparator", { fg = "#2f5a2f", bg = "#000000" })
  s(0, "NeoTreeFloatBorder", { fg = "#00ff41", bg = "#000000" })
  s(0, "NeoTreeTitleBar", { fg = "#000000", bg = "#00ff41" })
  s(0, "NeoTreeDotfile", { fg = "#4f7f5a" })
  s(0, "NeoTreeGitModified", { fg = "#d7ff5f" })
  s(0, "NeoTreeGitUntracked", { fg = "#5fbf5f" })
  s(0, "NeoTreeGitAdded", { fg = "#00ff41" })
  s(0, "NeoTreeGitConflict", { fg = "#ff5f5f" })
end
hl()
vim.api.nvim_create_autocmd("ColorScheme", { callback = hl })
