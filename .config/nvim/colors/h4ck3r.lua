-- h4ck3r: matrix green colorscheme for sys7mfaul7
vim.cmd("hi clear"); vim.g.colors_name = "h4ck3r"; vim.o.termguicolors = true
local c = { bg="#000000", bg2="#0f1a14", sel="#1f6f2f", dim="#2f5a2f", mid="#5fbf5f",
  fg="#c0ffc0", hi="#00ff41", br="#8fef8f", red="#ff5f5f", amb="#e6db74", wht="#ffffff" }
local function h(g, o) vim.api.nvim_set_hl(0, g, o) end
h("Normal",{fg=c.fg,bg=c.bg}); h("NormalFloat",{fg=c.fg,bg=c.bg2}); h("FloatBorder",{fg=c.hi,bg=c.bg2})
h("CursorLine",{bg=c.bg2}); h("CursorLineNr",{fg=c.hi,bold=true}); h("LineNr",{fg=c.dim})
h("Visual",{bg=c.sel}); h("Search",{fg=c.bg,bg=c.mid}); h("IncSearch",{fg=c.bg,bg=c.hi})
h("StatusLine",{fg=c.hi,bg=c.bg2}); h("StatusLineNC",{fg=c.dim,bg=c.bg2}); h("WinSeparator",{fg=c.dim})
h("Pmenu",{fg=c.fg,bg=c.bg2}); h("PmenuSel",{fg=c.wht,bg=c.sel}); h("SignColumn",{bg=c.bg})
h("MatchParen",{fg=c.hi,bold=true,underline=true}); h("NonText",{fg=c.dim}); h("Folded",{fg=c.mid,bg=c.bg2})
h("Comment",{fg=c.dim,italic=true}); h("Constant",{fg=c.br}); h("String",{fg=c.mid})
h("Number",{fg=c.br}); h("Identifier",{fg=c.fg}); h("Function",{fg=c.hi,bold=true})
h("Statement",{fg=c.hi}); h("Keyword",{fg=c.hi,bold=true}); h("Type",{fg=c.br})
h("PreProc",{fg=c.mid}); h("Special",{fg=c.br}); h("Operator",{fg=c.fg}); h("Todo",{fg=c.bg,bg=c.hi,bold=true})
h("Error",{fg=c.red}); h("ErrorMsg",{fg=c.red}); h("WarningMsg",{fg=c.amb})
h("DiagnosticError",{fg=c.red}); h("DiagnosticWarn",{fg=c.amb}); h("DiagnosticInfo",{fg=c.mid}); h("DiagnosticHint",{fg=c.dim})
h("DiffAdd",{fg=c.hi,bg=c.bg2}); h("DiffChange",{fg=c.amb}); h("DiffDelete",{fg=c.red})
h("@variable",{fg=c.fg}); h("@function",{link="Function"}); h("@keyword",{link="Keyword"}); h("@string",{link="String"})
h("@type",{link="Type"}); h("@comment",{link="Comment"}); h("@constant",{link="Constant"}); h("@property",{fg=c.br})
