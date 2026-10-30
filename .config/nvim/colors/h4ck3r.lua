-- h4ck3r: matrix green colorscheme for sys7mfaul7
vim.cmd("hi clear"); vim.g.colors_name = "h4ck3r"; vim.o.termguicolors = true
local c = { bg="#000000", bg2="#0f1a14", sel="#1f6f2f", dim="#2f5a2f", mid="#5fbf5f",
  fg="#c0ffc0", hi="#00ff41", br="#8fef8f", red="#ff5f5f", amb="#e6db74", wht="#ffffff",
  num="#2f5a31", slf="#00ff42", slb="#0f1a15", ncf="#2f5a30", ncb="#0f1a16",
  act="#000a03", nc="#000001" } -- act: focused-window bg, nc: unfocused bg (rice-mapped)
local function h(g, o) vim.api.nvim_set_hl(0, g, o) end
h("Normal",{fg=c.fg,bg=c.act}); h("NormalNC",{fg=c.fg,bg=c.nc}); h("EndOfBuffer",{fg=c.dim}); h("NormalFloat",{fg=c.fg,bg=c.bg2}); h("FloatBorder",{fg=c.hi,bg=c.bg2})
h("CursorLine",{bg=c.bg2}); h("CursorLineNr",{fg=c.hi,bold=true}); h("LineNr",{fg=c.num})
h("Visual",{bg=c.sel}); h("Search",{fg=c.bg,bg=c.mid}); h("IncSearch",{fg=c.bg,bg=c.hi})
h("StatusLine",{fg=c.bg,bg=c.hi,bold=true}); h("StatusLineNC",{fg=c.slf,bg=c.slb}); h("WinSeparator",{fg=c.dim})
h("Pmenu",{fg=c.fg,bg=c.bg2}); h("PmenuSel",{fg=c.wht,bg=c.sel}); h("SignColumn",{})
h("MatchParen",{fg=c.hi,bold=true,underline=true}); h("NonText",{fg=c.dim}); h("Folded",{fg=c.mid,bg=c.bg2})
h("Comment",{fg=c.num,italic=true}); h("Constant",{fg=c.br}); h("String",{fg=c.mid})
h("Number",{fg=c.br}); h("Identifier",{fg=c.fg}); h("Function",{fg=c.hi,bold=true})
h("Statement",{fg=c.hi}); h("Keyword",{fg=c.hi,bold=true}); h("Type",{fg=c.br})
h("PreProc",{fg=c.mid}); h("Special",{fg=c.br}); h("Operator",{fg=c.fg}); h("Todo",{fg=c.bg,bg=c.hi,bold=true})
h("Error",{fg=c.red}); h("ErrorMsg",{fg=c.red}); h("WarningMsg",{fg=c.amb})
h("DiagnosticError",{fg=c.red}); h("DiagnosticWarn",{fg=c.amb}); h("DiagnosticInfo",{fg=c.mid}); h("DiagnosticHint",{fg=c.num})
h("DiffAdd",{fg=c.hi,bg=c.bg2}); h("DiffChange",{fg=c.amb}); h("DiffDelete",{fg=c.red})
h("@variable",{fg=c.fg}); h("@function",{link="Function"}); h("@keyword",{link="Keyword"}); h("@string",{link="String"})
h("@type",{link="Type"}); h("@comment",{link="Comment"}); h("@constant",{link="Constant"}); h("@property",{fg=c.br})
-- readable-number/comment and statusline tokens: in green these are 1 step off the base
-- colours (look identical); other themes map them on their own (see rices/*/theme.conf)
-- Neovim default groups that otherwise fall back to Nvim(Light|Dark)* (green/cyan remnants)
h("ModeMsg",{fg=c.hi,bold=true}); h("MoreMsg",{fg=c.mid}); h("OkMsg",{fg=c.hi}); h("Question",{fg=c.mid})
h("Title",{fg=c.hi,bold=true}); h("Directory",{fg=c.hi}); h("QuickFixLine",{fg=c.hi,bold=true})
h("CurSearch",{fg=c.bg,bg=c.hi}); h("Conceal",{fg=c.num}); h("ColorColumn",{bg=c.bg2}); h("CursorColumn",{bg=c.bg2})
h("WinBar",{fg=c.fg,bg=c.bg}); h("WinBarNC",{fg=c.num,bg=c.bg}); h("Delimiter",{fg=c.fg}); h("@punctuation",{fg=c.fg})
-- nvim-window-picker labels (Alt+w): accent label (dark text on accent) on every pickable window
h("WinPick",{fg=c.bg,bg=c.hi,bold=true}); h("WinPickNC",{fg=c.bg,bg=c.hi,bold=true})
h("@markup.heading",{fg=c.hi,bold=true}); h("PreInsert",{fg=c.num}); h("TabLine",{fg=c.ncf,bg=c.ncb})
h("TabLineSel",{fg=c.slf,bg=c.slb}); h("TabLineFill",{bg=c.bg}); h("WildMenu",{fg=c.wht,bg=c.sel})
h("Added",{fg=c.hi}); h("Changed",{fg=c.amb}); h("Removed",{fg=c.red})
h("@diff.plus",{link="Added"}); h("@diff.minus",{link="Removed"}); h("@diff.delta",{link="Changed"})
h("DiagnosticOk",{fg=c.mid}); h("DiagnosticUnderlineOk",{undercurl=true,sp=c.mid})
h("DiagnosticUnderlineInfo",{undercurl=true,sp=c.mid}); h("DiagnosticUnderlineHint",{undercurl=true,sp=c.num})
h("SpellBad",{undercurl=true,sp=c.red}); h("SpellCap",{undercurl=true,sp=c.amb})
h("SpellLocal",{undercurl=true,sp=c.mid}); h("SpellRare",{undercurl=true,sp=c.br})
h("WhichKeyIconGreen",{fg=c.hi}); h("RenderMarkdownSuccess",{fg=c.mid}); h("RenderMarkdownTableHead",{fg=c.mid})
h("CsvViewInfoPositive",{fg=c.mid}); h("CodeCompanionChatToolSuccess",{fg=c.mid})
-- inline hints / ghost text / fzf info line: readable dim, not the border grey
h("ComplHint",{fg=c.num}); h("ComplHintMore",{fg=c.mid}); h("BlinkCmpGhostText",{fg=c.num,italic=true})
h("LspCodeLens",{fg=c.num}); h("LspCodeLensSeparator",{fg=c.num}); h("FzfLuaFzfInfo",{fg=c.num})

-- Transparency (default on; :TransparentToggle / <leader>ut). Backgrounds go NONE so foot's
-- alpha shows through. foot only blends its *default* bg, so a tinted active window can't be
-- translucent; the active-window cues become: accent status line, cursorline only in the
-- focused window (ui.lua), and dimmer text in inactive windows. Off = the opaque tinted look.
if vim.g.h4ck3r_transparent == nil then vim.g.h4ck3r_transparent = true end
if vim.g.h4ck3r_transparent then
  for _, g in ipairs({ "Normal", "SignColumn", "EndOfBuffer", "FoldColumn", "LineNr", "CursorLineNr",
    "LineNrAbove", "LineNrBelow", "WinBar", "WinBarNC", "TabLineFill", "NormalFloat", "FloatBorder",
    "FloatTitle", "Folded", "NeoTreeNormal", "NeoTreeNormalNC", "NeoTreeEndOfBuffer",
    "FzfLuaNormal", "FzfLuaBorder", "WhichKeyFloat", "WhichKeyNormal", "BlinkCmpMenu" }) do
    local cur = vim.api.nvim_get_hl(0, { name = g, link = false })
    cur.bg = nil; cur.ctermbg = nil; vim.api.nvim_set_hl(0, g, cur)
  end
  h("NormalNC", { fg = c.ncf })   -- inactive: transparent + dimmer text
  h("CursorLine", { bg = c.bg2 })  -- focused window only (ui.lua), stays solid as the cue
end
if not vim.g.h4ck3r_toggle_defined then
  vim.g.h4ck3r_toggle_defined = true
  vim.api.nvim_create_user_command("TransparentToggle", function()
    vim.g.h4ck3r_transparent = not vim.g.h4ck3r_transparent
    vim.cmd.colorscheme(vim.g.colors_name or "h4ck3r")
    vim.notify("transparency " .. (vim.g.h4ck3r_transparent and "on" or "off"))
  end, { desc = "Toggle transparent background" })
  vim.keymap.set("n", "<leader>ut", "<cmd>TransparentToggle<cr>", { desc = "UI: toggle transparency" })
end
