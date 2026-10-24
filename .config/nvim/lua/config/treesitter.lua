local ok, ts = pcall(require, "nvim-treesitter.configs")
if not ok then return end
ts.setup({
  ensure_installed = { "c", "cpp", "rust", "python", "lua", "luadoc", "java", "go", "gomod", "gosum",
    "ruby", "commonlisp", "scheme", "json", "jsonc", "jq", "html", "css", "xml", "csv", "tsv",
    "powershell", "bash", "asm", "nasm", "markdown", "markdown_inline", "yaml", "toml", "vim",
    "vimdoc", "query", "javascript", "typescript", "bicep", "regex", "make", "cmake" },
  sync_install = false,
  auto_install = false,
  highlight = { enable = true },
  indent = { enable = true },
})
