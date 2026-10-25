-- Git: gitsigns (gutter), diffview (diffs/history), neogit (Magit-style), octo (GitHub via gh)
local map = vim.keymap.set
local function try(m) local ok, r = pcall(require, m); return ok and r or nil end

local gs = try("gitsigns")
if gs then
  gs.setup({
    signs = { add = { text = "┃" }, change = { text = "┃" }, delete = { text = "_" },
              topdelete = { text = "‾" }, changedelete = { text = "~" }, untracked = { text = "┆" } },
    current_line_blame_opts = { delay = 400 },
    on_attach = function(buf)
      local o = function(d) return { buffer = buf, desc = d } end
      map("n", "]h", function() gs.nav_hunk("next") end, o("Next hunk"))
      map("n", "[h", function() gs.nav_hunk("prev") end, o("Prev hunk"))
      map("n", "<leader>hs", gs.stage_hunk, o("Stage hunk"))
      map("n", "<leader>hr", gs.reset_hunk, o("Reset hunk"))
      map("n", "<leader>hp", gs.preview_hunk, o("Preview hunk"))
      map("n", "<leader>hb", function() gs.blame_line({ full = true }) end, o("Blame line"))
      map("n", "<leader>hB", gs.toggle_current_line_blame, o("Toggle inline blame"))
      map("n", "<leader>hd", gs.diffthis, o("Diff this file"))
    end,
  })
end

local dv = try("diffview")
if dv then
  dv.setup({ enhanced_diff_hl = true, use_icons = true })
  map("n", "<leader>gd", "<cmd>DiffviewOpen<cr>", { desc = "Diff working tree" })
  map("n", "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", { desc = "File history" })
  map("n", "<leader>gH", "<cmd>DiffviewFileHistory<cr>", { desc = "Repo history" })
  map("n", "<leader>gq", "<cmd>DiffviewClose<cr>", { desc = "Close diffview" })
end

local ng = try("neogit")
if ng then
  ng.setup({ integrations = { diffview = true, fzf_lua = true }, graph_style = "unicode" })
  map("n", "<leader>gg", "<cmd>Neogit<cr>", { desc = "Neogit status" })
  map("n", "<leader>gc", "<cmd>Neogit commit<cr>", { desc = "Commit" })
end

local fz = try("fzf-lua")
if fz then fz.setup({ winopts = { border = "single" }, fzf_colors = true }) end

local oc = try("octo")
if oc then
  oc.setup({ picker = "fzf-lua", enable_builtin = true, default_to_projects_v2 = false })
  map("n", "<leader>go", "<cmd>Octo<cr>", { desc = "GitHub (Octo) menu" })
  map("n", "<leader>gi", "<cmd>Octo issue list<cr>", { desc = "GitHub issues" })
  map("n", "<leader>gp", "<cmd>Octo pr list<cr>", { desc = "GitHub PRs" })
  map("n", "<leader>gr", "<cmd>Octo repo list<cr>", { desc = "My GitHub repos" })
end

local wk = try("which-key")
if wk then wk.add({ { "<leader>g", group = "Git / GitHub" }, { "<leader>h", group = "Git hunks" } }) end

local function hl()
  local s = vim.api.nvim_set_hl
  s(0, "GitSignsAdd", { fg = "#00ff41" }); s(0, "GitSignsChange", { fg = "#d7ff5f" })
  s(0, "GitSignsDelete", { fg = "#ff5f5f" }); s(0, "GitSignsUntracked", { fg = "#4f7f5a" })
  s(0, "GitSignsCurrentLineBlame", { fg = "#4f7f5a", italic = true })
  s(0, "DiffAdd", { bg = "#0f2a14" }); s(0, "DiffChange", { bg = "#1a1f0f" })
  s(0, "DiffDelete", { fg = "#5f2f2f", bg = "#1a0a0a" }); s(0, "DiffText", { bg = "#2f4a14", bold = true })
  s(0, "NeogitBranch", { fg = "#00ff41", bold = true }); s(0, "NeogitRemote", { fg = "#5fbf5f", bold = true })
  s(0, "NeogitSectionHeader", { fg = "#00ff41", bold = true })
  s(0, "NeogitHunkHeader", { fg = "#000000", bg = "#4f7f5a" })
  s(0, "NeogitHunkHeaderHighlight", { fg = "#000000", bg = "#00ff41", bold = true })
  s(0, "NeogitDiffAdd", { fg = "#00ff41", bg = "#0f2a14" }); s(0, "NeogitDiffDelete", { fg = "#ff5f5f", bg = "#1a0a0a" })
  s(0, "NeogitDiffContext", { fg = "#c0ffc0", bg = "#000000" })
  s(0, "NeogitDiffAddHighlight", { fg = "#00ff41", bg = "#12301a" }); s(0, "NeogitDiffDeleteHighlight", { fg = "#ff5f5f", bg = "#2a0f0f" })
  s(0, "NeogitDiffContextHighlight", { fg = "#c0ffc0", bg = "#0f1a14" })
  s(0, "FzfLuaBorder", { fg = "#00ff41" }); s(0, "FzfLuaTitle", { fg = "#000000", bg = "#00ff41", bold = true })
end
hl()
vim.api.nvim_create_autocmd("ColorScheme", { callback = hl })
