-- Window navigation: smart-splits (tmux-aware move/resize/swap) + nvim-window-picker
-- Keys chosen to avoid bspwm-wl/sxhkd grabs (Ctrl+Alt+h/l, Alt+Tab, Super+*) and
-- tmux (prefix C-Space). Ctrl+hjkl (keys.lua) keep working as before.
local map = vim.keymap.set
local ok, ss = pcall(require, "smart-splits")
if ok then
  ss.setup({ mux = vim.env.TMUX and { backend = "smart-splits-backend-tmux" } or nil, move = { at_edge = "stop" }, swap = { move_cursor = true }, resize = { amount = 3 } })
  local dirs = { h = "left", j = "down", k = "up", l = "right" }
  for k, d in pairs(dirs) do
    local K = k:upper()
    map("n", "<M-" .. k .. ">", ss["move_cursor_" .. d], { desc = "Win: go " .. d })
    map("n", "<M-" .. K .. ">", ss["resize_" .. d], { desc = "Win: resize " .. d })
    map("n", "<leader>w" .. k, ss["swap_buf_" .. d], { desc = "Win: swap " .. d })
    map("n", "<leader>w" .. K, "<C-w>" .. K, { desc = "Win: move to far " .. d })
  end
end
local okp, wp = pcall(require, "window-picker")
if okp then
  wp.setup({
    hint = "statusline-winbar",
    selection_chars = "FJDKSLAGHRUEIWO",
    filter_rules = { include_current_win = false, autoselect_one = true,
      bo = { filetype = { "notify", "noice", "neo-tree-popup" }, buftype = {} } },
    highlights = { enabled = true,
      statusline = { focused = "WinPick", unfocused = "WinPickNC" },
      winbar = { focused = "WinPick", unfocused = "WinPickNC" } },
  })
  local function jump() local w = wp.pick_window(); if w then vim.api.nvim_set_current_win(w) end end
  local function swap() -- swap current buffer with picked window, follow it
    local w = wp.pick_window(); if not w then return end
    local cur = vim.api.nvim_get_current_win()
    local b1, b2 = vim.api.nvim_win_get_buf(cur), vim.api.nvim_win_get_buf(w)
    vim.api.nvim_win_set_buf(cur, b2); vim.api.nvim_win_set_buf(w, b1); vim.api.nvim_set_current_win(w)
  end
  local function close() local w = wp.pick_window(); if w then vim.api.nvim_win_close(w, false) end end
  map("n", "<M-w>", jump, { desc = "Win: pick & jump" })
  map("n", "<leader>ww", jump, { desc = "Win: pick & jump" })
  map("n", "<leader>ws", swap, { desc = "Win: swap with picked" })
  map("n", "<leader>wx", close, { desc = "Win: close picked" })
end
map("n", "<leader>w=", "<C-w>=", { desc = "Win: equalize" })
map("n", "<leader>wo", "<C-w>o", { desc = "Win: only this" })
map("n", "<leader>wv", "<C-w>v", { desc = "Win: split right" })
map("n", "<leader>w-", "<C-w>s", { desc = "Win: split below" })
map("n", "<leader>wq", "<C-w>q", { desc = "Win: close" })
local okw, wk = pcall(require, "which-key")
if okw then pcall(wk.add, { { "<leader>w", group = "windows" } }) end
