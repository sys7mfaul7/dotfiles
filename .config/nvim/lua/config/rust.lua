-- Rust: rustaceanvim owns rust-analyzer (lspconfig rust_analyzer is NOT enabled in lsp.lua).
-- Generic LSP keys (gd, K, <leader>ca, <leader>rn, <leader>ih) still come from lsp.lua LspAttach.
vim.g.rustaceanvim = {
  tools = { float_win_config = { border = "rounded" } },
  server = {
    cmd = { "rust-analyzer" }, -- Guix binary
    default_settings = { ["rust-analyzer"] = {
      check = { command = "clippy" },
      cargo = { allFeatures = true },
      inlayHints = { closingBraceHints = { minLines = 20 } },
    } },
    on_attach = function(_, buf)
      vim.lsp.inlay_hint.enable(true, { bufnr = buf })
      local m = function(lhs, args, d, mode)
        vim.keymap.set(mode or "n", lhs, function() vim.cmd.RustLsp(args) end, { buffer = buf, desc = d })
      end
      m("<leader>Ra", "codeAction", "Rust code action (grouped)", { "n", "v" })
      m("<leader>Rr", "runnables", "Rust runnables")
      m("<leader>Rt", "testables", "Rust testables")
      m("<leader>Rd", "debuggables", "Rust debuggables (lldb-dap)")
      m("<leader>Rh", { "hover", "actions" }, "Rust hover actions")
      m("<leader>Rm", "expandMacro", "Rust expand macro")
      m("<leader>Re", "explainError", "Rust explain error")
      m("<leader>RD", "renderDiagnostic", "Rust render diagnostic")
      m("<leader>Rc", "openCargo", "Open Cargo.toml")
      m("<leader>Rp", "parentModule", "Rust parent module")
      m("<leader>Rj", "joinLines", "Rust join lines")
      m("<leader>Rk", { "moveItem", "up" }, "Rust move item up")
      m("<leader>RJ", { "moveItem", "down" }, "Rust move item down")
      m("<leader>Rx", "openDocs", "Rust open docs.rs")
    end,
  },
}
if vim.fn.executable("lldb-dap") == 1 then
  vim.g.rustaceanvim.dap = { adapter = { type = "executable", command = "lldb-dap", name = "lldb" } }
end

local okc, crates = pcall(require, "crates")
if okc then
  crates.setup({ lsp = { enabled = true, actions = true, completion = true, hover = true },
    popup = { border = "rounded" } })
  vim.api.nvim_create_autocmd("BufRead", { pattern = "Cargo.toml", callback = function(ev)
    local o = function(d) return { buffer = ev.buf, desc = d } end
    vim.keymap.set("n", "<leader>Rv", crates.show_versions_popup, o("Crate versions"))
    vim.keymap.set("n", "<leader>Rf", crates.show_features_popup, o("Crate features"))
    vim.keymap.set("n", "<leader>Ru", crates.upgrade_crate, o("Upgrade crate"))
    vim.keymap.set("n", "<leader>RU", crates.upgrade_all_crates, o("Upgrade all crates"))
  end })
end
local okw, wk = pcall(require, "which-key")
if okw then wk.add({ { "<leader>R", group = "Rust" } }) end
