local ok, lint = pcall(require, "lint")
if not ok then return end
local want = {
  c = { "clangtidy" }, cpp = { "clangtidy" },
  python = { "ruff" }, go = { "golangcilint" }, ruby = { "rubocop" },
  sh = { "shellcheck" }, bash = { "shellcheck" },
  json = { "jsonlint" }, markdown = { "markdownlint-cli2" }, lua = { "luacheck" }, yaml = { "yamllint" },
}
-- only keep linters whose binary exists (rust: clippy runs via rust-analyzer)
local by_ft = {}
for ft, ls in pairs(want) do
  for _, n in ipairs(ls) do
    local l = lint.linters[n]
    local cmd = l and (type(l) == "function" and l().cmd or l.cmd)
    if type(cmd) == "function" then cmd = cmd() end
    if cmd and vim.fn.executable(cmd) == 1 then
      by_ft[ft] = by_ft[ft] or {}; table.insert(by_ft[ft], n)
    end
  end
end
lint.linters_by_ft = by_ft
vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
  callback = function() lint.try_lint() end,
})
vim.keymap.set("n", "<leader>l", function() lint.try_lint() end, { desc = "Lint" })
