local ok, conform = pcall(require, "conform")
if not ok then return end
vim.g.format_on_save = false -- opt-in; :FormatToggle
conform.setup({
  formatters_by_ft = {
    c = { "clang_format" }, cpp = { "clang_format" },
    rust = { "rustfmt" },
    python = { "ruff_fix", "ruff_format", "ruff_organize_imports" },
    lua = { "stylua" },
    go = { "goimports", "gofumpt" },
    ruby = { "rubocop" },
    json = { "prettier", "jq", stop_after_first = true }, jsonc = { "prettier" },
    jq = { "jq" },
    html = { "prettier" }, css = { "prettier" }, scss = { "prettier" },
    javascript = { "prettier" }, typescript = { "prettier" }, yaml = { "prettier" },
    markdown = { "prettier", "markdownlint-cli2" },
    xml = { "xmllint" },
    sh = { "shfmt" }, bash = { "shfmt" },
    java = { lsp_format = "prefer" },
    nasm = { lsp_format = "prefer" },
    ["_"] = { "trim_whitespace", lsp_format = "fallback" },
  },
  default_format_opts = { lsp_format = "fallback" },
  format_on_save = function()
    if vim.g.format_on_save then return { timeout_ms = 1500, lsp_format = "fallback" } end
  end,
})
vim.api.nvim_create_user_command("FormatToggle", function()
  vim.g.format_on_save = not vim.g.format_on_save
  vim.notify("Format on save: " .. (vim.g.format_on_save and "ON" or "OFF"))
end, {})
vim.keymap.set({ "n", "v" }, "<leader>f", function() conform.format({ async = true }) end, { desc = "Format" })
vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
