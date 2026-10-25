-- Editing defaults and core keymaps
local o = vim.o
o.tabstop = 4; o.shiftwidth = 4; o.softtabstop = 4; o.expandtab = true
o.timeoutlen = 300 -- which-key pops up 300 ms after <Space>

local map = vim.keymap.set
-- Esc clears search highlight
-- (set after plugins load: llama.vim also maps <Esc>, so keep its cancel too)
local function esc_map()
  map("n", "<Esc>", function()
    vim.cmd("nohlsearch")
    if vim.fn.exists("*llama#inst_cancel") == 1 then pcall(vim.fn["llama#inst_cancel"]) end
    return "<Esc>"
  end, { expr = true, desc = "Clear search highlight" })
end
esc_map()
vim.api.nvim_create_autocmd("VimEnter", { once = true, callback = esc_map })
-- Ctrl+hjkl / Ctrl+arrows move between windows (Ctrl+w h/j/k/l)
for key, dir in pairs({ h = "h", j = "j", k = "k", l = "l", Left = "h", Down = "j", Up = "k", Right = "l" }) do
  map("n", "<C-" .. key .. ">", "<C-w>" .. dir, { desc = "Window " .. ({ h = "left", j = "down", k = "up", l = "right" })[dir] })
end

-- which-key: press <Space> and wait to see leader keybinds
local ok, wk = pcall(require, "which-key")
if ok then
  wk.setup({
    preset = "classic",
    delay = 300,
    icons = { mappings = false },
    win = { border = "single" },
  })
  wk.add({
    { "<leader>a", group = "AI" },
  })
  local function hl()
    local s = vim.api.nvim_set_hl
    s(0, "WhichKey", { fg = "#00ff41", bold = true })
    s(0, "WhichKeyGroup", { fg = "#5fbf5f" })
    s(0, "WhichKeyDesc", { fg = "#c0ffc0" })
    s(0, "WhichKeySeparator", { fg = "#4f7f5a" })
    s(0, "WhichKeyNormal", { bg = "#000000" })
    s(0, "WhichKeyBorder", { fg = "#00ff41", bg = "#000000" })
    s(0, "WhichKeyTitle", { fg = "#00ff41", bg = "#000000", bold = true })
    s(0, "WhichKeyValue", { fg = "#4f7f5a" })
  end
  hl()
  vim.api.nvim_create_autocmd("ColorScheme", { callback = hl })
end
