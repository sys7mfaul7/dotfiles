local ok, blink = pcall(require, "blink.cmp")
if not ok then return end
blink.setup({
  keymap = { preset = "default" }, -- C-space open, C-y accept, C-n/C-p select, C-e close
  appearance = { nerd_font_variant = "mono" },
  completion = {
    menu = { border = "rounded" },
    documentation = { auto_show = true, auto_show_delay_ms = 300, window = { border = "rounded" } },
    ghost_text = { enabled = false }, -- llama.vim owns ghost text
  },
  signature = { enabled = true, window = { border = "rounded" } },
  sources = { default = { "lsp", "path", "snippets", "buffer" } },
  fuzzy = { implementation = "prefer_rust" },
})
