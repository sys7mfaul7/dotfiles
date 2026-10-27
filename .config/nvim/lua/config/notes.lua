-- Markdown: in-buffer rendering
local okr, rm = pcall(require, "render-markdown")
if okr then
  rm.setup({ file_types = { "markdown", "codecompanion" },
    heading = { backgrounds = { "H4Head1", "H4Head2", "H4Head3", "H4Head4", "H4Head5", "H4Head6" } },
    code = { highlight = "H4Code" },
    latex = { enabled = false },
    -- rendered in normal/command/terminal AND insert; the raw markdown of the cursor line
    -- (anti-conceal) is only revealed while typing in insert mode, so moving over a table
    -- in normal mode no longer collapses the row into raw pipes
    render_modes = { "n", "c", "t", "i" },
    anti_conceal = { enabled = true, disabled_modes = { "n", "c", "t" } },
    pipe_table = { cell = "padded", wrap = true } })
end
-- Org mode
local oko, org = pcall(require, "orgmode")
if oko then
  vim.fn.mkdir(vim.fn.expand("~/org"), "p")
  org.setup({
    org_agenda_files = "~/org/**/*",
    org_default_notes_file = "~/org/refile.org",
  })
end
vim.api.nvim_create_autocmd("FileType", { pattern = "org", once = true, callback = function(ev)
  vim.cmd.packadd("headlines.nvim")
  local okh, hl = pcall(require, "headlines")
  if not okh then return end
  hl.setup({
    org = { headline_highlights = { "H4Head1", "H4Head2", "H4Head3", "H4Head4", "H4Head5", "H4Head6" },
      bullets = { "◉", "○", "✸", "✿" }, codeblock_highlight = "H4Code", dash_highlight = "H4Dash",
      quote_highlight = "H4Dash", fat_headlines = false },
  })
  for ft in pairs(hl.config) do if ft ~= "org" then hl.config[ft] = nil end end
  vim.api.nvim_buf_call(ev.buf, function() pcall(hl.refresh) end)
end })
local function colors()
  local s = function(g, o) vim.api.nvim_set_hl(0, g, o) end
  local fg = { "#00ff41", "#8fef8f", "#c0ffc0", "#5fbf5f", "#4f9f4f", "#3f7f3f" }
  for i = 1, 6 do
    s("H4Head" .. i, { fg = fg[i], bg = i == 1 and "#12301a" or "#0f1a14", bold = true })
    s("@markup.heading." .. i .. ".markdown", { fg = fg[i], bold = true })
    s("RenderMarkdownH" .. i, { fg = fg[i], bold = true })
    s("RenderMarkdownH" .. i .. "Bg", { link = "H4Head" .. i })
    s("@org.headline.level" .. i, { fg = fg[i], bold = true })
  end
  s("H4Code", { bg = "#0f1a14" }); s("H4Dash", { fg = "#2f5a2f" })
  s("RenderMarkdownCode", { link = "H4Code" }); s("RenderMarkdownBullet", { fg = "#00ff41" })
  s("@org.keyword.todo", { fg = "#ff3b3b", bold = true }); s("@org.keyword.done", { fg = "#5fbf5f", bold = true })
  s("@org.agenda.scheduled", { fg = "#c0ffc0" }); s("@org.agenda.deadline", { fg = "#ffb000" })
end
colors()
vim.api.nvim_create_autocmd("ColorScheme", { callback = colors })
-- Markdown windows: keep the number column through soft-wrapped lines and through
-- render-markdown's virtual lines (wrapped table cells) instead of a blank gap
_G.H4MdStc = function()
  if vim.v.virtnum ~= 0 then return "%#LineNr#   │ " end
  local n = (vim.wo.relativenumber and vim.v.relnum > 0) and vim.v.relnum or vim.v.lnum
  return "%s%=" .. (vim.v.relnum == 0 and "%#CursorLineNr#" or "%#LineNr#") .. n .. " "
end
vim.api.nvim_create_autocmd({ "FileType", "BufWinEnter" }, {
  group = vim.api.nvim_create_augroup("user_md_numbers", { clear = true }),
  callback = function(ev)
    local md = vim.bo[ev.buf].filetype == "markdown"
    if md then vim.wo.statuscolumn = "%!v:lua.H4MdStc()"; vim.w.h4_md_stc = true
    elseif vim.w.h4_md_stc then vim.wo.statuscolumn = ""; vim.w.h4_md_stc = nil end
  end,
})
