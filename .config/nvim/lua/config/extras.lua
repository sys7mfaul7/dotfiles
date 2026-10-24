local ok, csv = pcall(require, "csvview")
if ok then
  csv.setup({ view = { display_mode = "border" } })
  vim.api.nvim_create_autocmd("FileType", { pattern = { "csv", "tsv" },
    callback = function(ev) pcall(csv.enable, ev.buf) end })
end
-- Conjure: Scheme via Guile REPL, Common Lisp via Swank (sbcl)
vim.g["conjure#filetypes"] = { "clojure", "fennel", "janet", "hy", "julia", "racket", "scheme", "lua", "lisp", "python", "rust", "sql" }
vim.g["conjure#filetype#scheme"] = "conjure.client.guile.socket"
vim.g["conjure#client#guile#socket#pipename"] = ".guile-repl.socket"
vim.g["conjure#filetype#python"] = false
vim.g["conjure#filetype#lua"] = false
vim.g["conjure#filetype#rust"] = false
vim.g["conjure#filetype#sql"] = false
