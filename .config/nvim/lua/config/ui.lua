-- h4ck3r palette for LSP/completion/DAP UI
local p = { bg = "#000000", bg2 = "#0f1a14", fg = "#c0ffc0", acc = "#00ff41",
  sel = "#1f6f2f", dim = "#2f5a2f", mid = "#5fbf5f", red = "#ff3b3b", amber = "#ffb000" }
local function hl()
  local s = function(g, o) vim.api.nvim_set_hl(0, g, o) end
  s("NormalFloat", { fg = p.fg, bg = p.bg2 })
  s("FloatBorder", { fg = p.acc, bg = p.bg2 })
  s("FloatTitle", { fg = p.acc, bg = p.bg2, bold = true })
  s("Pmenu", { fg = p.fg, bg = p.bg2 })
  s("PmenuSel", { fg = p.fg, bg = p.sel, bold = true })
  s("PmenuSbar", { bg = p.bg2 }); s("PmenuThumb", { bg = p.mid })
  s("BlinkCmpMenu", { link = "Pmenu" }); s("BlinkCmpMenuBorder", { link = "FloatBorder" })
  s("BlinkCmpMenuSelection", { link = "PmenuSel" }); s("BlinkCmpDoc", { link = "NormalFloat" })
  s("BlinkCmpDocBorder", { link = "FloatBorder" }); s("BlinkCmpLabelMatch", { fg = p.acc, bold = true })
  s("BlinkCmpKind", { fg = p.mid }); s("BlinkCmpSignatureHelpBorder", { link = "FloatBorder" })
  s("DiagnosticError", { fg = p.red }); s("DiagnosticWarn", { fg = p.amber })
  s("DiagnosticInfo", { fg = p.fg }); s("DiagnosticHint", { fg = p.mid })
  s("DiagnosticUnderlineError", { undercurl = true, sp = p.red })
  s("DiagnosticUnderlineWarn", { undercurl = true, sp = p.amber })
  s("LspReferenceText", { bg = p.sel }); s("LspReferenceRead", { bg = p.sel }); s("LspReferenceWrite", { bg = p.sel })
  s("LspInlayHint", { fg = "#2f5a31", italic = true }) -- readable-dim token (see colors/h4ck3r.lua)
  s("DapBreakpoint", { fg = p.red }); s("DapStopped", { fg = p.acc }); s("DapStoppedLine", { bg = p.sel })
  s("NvimDapVirtualText", { fg = p.mid, italic = true })
  for _, g in ipairs({ "DapUIScope", "DapUIBreakpointsPath", "DapUIDecoration", "DapUIStoppedThread",
      "DapUIWatchesValue", "DapUIPlayPause", "DapUIRestart", "DapUIStepOver", "DapUIStepInto",
      "DapUIStepOut", "DapUIStepBack" }) do s(g, { fg = p.acc }) end
  s("DapUIType", { fg = p.mid }); s("DapUIValue", { fg = p.fg }); s("DapUIVariable", { fg = p.fg })
  s("DapUIModifiedValue", { fg = p.acc, bold = true }); s("DapUIThread", { fg = p.mid })
  s("DapUIFloatBorder", { fg = p.acc }); s("DapUIWatchesError", { fg = p.red }); s("DapUIStop", { fg = p.red })
  s("DapUILineNumber", { fg = p.mid }); s("DapUIBreakpointsCurrentLine", { fg = p.acc, bold = true })
  s("CsvViewDelimiter", { fg = p.dim })
end
hl()
vim.api.nvim_create_autocmd("ColorScheme", { callback = hl })
vim.o.winborder = "rounded"
vim.diagnostic.config({
  virtual_text = { prefix = "●", spacing = 2 },
  severity_sort = true,
  float = { border = "rounded", source = true },
  signs = { text = { [vim.diagnostic.severity.ERROR] = "E", [vim.diagnostic.severity.WARN] = "W",
    [vim.diagnostic.severity.INFO] = "I", [vim.diagnostic.severity.HINT] = "H" } },
})
-- extra filetypes
vim.filetype.add({
  extension = { mojo = "mojo", ["🔥"] = "mojo", asm = "nasm", nasm = "nasm", jq = "jq",
    bicep = "bicep", bicepparam = "bicep", ps1 = "ps1", psm1 = "ps1", psd1 = "ps1",
    csh = "csh", tcsh = "tcsh", scm = "scheme", sld = "scheme" },
})
