-- Native LSP (vim.lsp.config / vim.lsp.enable); nvim-lspconfig supplies default configs.
local caps = vim.lsp.protocol.make_client_capabilities()
local okb, blink = pcall(require, "blink.cmp")
if okb then caps = blink.get_lsp_capabilities(caps) end
vim.lsp.config("*", { capabilities = caps })

vim.lsp.config("lua_ls", { settings = { Lua = {
  runtime = { version = "LuaJIT" },
  workspace = { checkThirdParty = false, library = { vim.env.VIMRUNTIME } },
  diagnostics = { globals = { "vim" } }, telemetry = { enable = false } } } })
vim.lsp.config("rust_analyzer", { settings = { ["rust-analyzer"] = { check = { command = "clippy" } } } })
vim.lsp.config("basedpyright", { settings = { basedpyright = { analysis = { typeCheckingMode = "standard" } } } })
vim.lsp.config("gopls", { settings = { gopls = { gofumpt = true, staticcheck = true } } })
-- Mojo: activates only if Modular's mojo-lsp-server is on PATH (install via pixi/magic)
vim.lsp.config("mojo", { cmd = { "mojo-lsp-server" }, filetypes = { "mojo" },
  root_markers = { "pixi.toml", "mojoproject.toml", ".git" } })

vim.lsp.config("asm_lsp", { filetypes = { "asm", "nasm", "vmasm" } })

-- server name -> executable that must exist for it to be enabled
local servers = {
  clangd = "clangd", basedpyright = "basedpyright-langserver",
  ruff = "ruff", mojo = "mojo-lsp-server", lua_ls = "lua-language-server", jdtls = "jdtls",
  gopls = "gopls", ruby_lsp = "ruby-lsp", solargraph = "solargraph",
  jsonls = "vscode-json-language-server", jqls = "jq-lsp", html = "vscode-html-language-server",
  cssls = "vscode-css-language-server", lemminx = "lemminx", powershell_es = "pwsh",
  bicep = "bicep-langserver", bashls = "bash-language-server", asm_lsp = "asm-lsp", marksman = "marksman",
}
-- pylsp only as fallback if basedpyright missing
if vim.fn.executable("basedpyright-langserver") == 0 then servers.pylsp = "pylsp" end
if vim.fn.executable("ruby-lsp") == 1 then servers.solargraph = nil end
local enabled = {}
for name, exe in pairs(servers) do
  if vim.fn.executable(exe) == 1 then table.insert(enabled, name) end
end
vim.lsp.enable(enabled)
vim.g.lsp_enabled_servers = enabled

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(ev)
    local o = function(d) return { buffer = ev.buf, desc = d } end
    local m = vim.keymap.set
    m("n", "gd", vim.lsp.buf.definition, o("Goto definition"))
    m("n", "gD", vim.lsp.buf.declaration, o("Goto declaration"))
    m("n", "gr", vim.lsp.buf.references, o("References"))
    m("n", "gi", vim.lsp.buf.implementation, o("Implementation"))
    m("n", "K", vim.lsp.buf.hover, o("Hover"))
    m("n", "<leader>rn", vim.lsp.buf.rename, o("Rename"))
    m({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, o("Code action"))
    m("n", "<leader>e", vim.diagnostic.open_float, o("Line diagnostics"))
    m("n", "[d", function() vim.diagnostic.jump({ count = -1, float = true }) end, o("Prev diagnostic"))
    m("n", "]d", function() vim.diagnostic.jump({ count = 1, float = true }) end, o("Next diagnostic"))
    m("n", "<leader>ih", function()
      vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = ev.buf }), { bufnr = ev.buf })
    end, o("Toggle inlay hints"))
  end,
})
