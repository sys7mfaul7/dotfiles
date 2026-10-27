-- Guix's neovim only loads tree-sitter parsers from TREE_SITTER_GRAMMAR_PATH;
-- fall back to the standard runtimepath parser/<lang>.so (nvim-treesitter, orgmode).
do
  local lang_mod = vim.treesitter.language
  local orig_add = lang_mod.add
  lang_mod.add = function(lang, opts)
    opts = opts or {}
    if opts.path == nil and not vim._ts_has_language(lang:lower()) then
      local f = vim.api.nvim_get_runtime_file("parser/" .. lang:lower() .. ".so", false)[1]
      if f then
        local o = vim.deepcopy(opts); o.path = f
        local ok, res, err = pcall(orig_add, lang, o)
        if ok and res then return res end
      end
    end
    return orig_add(lang, opts)
  end
end

-- Neovim 0.12 async tree-sitter parsing + render-markdown's synchronous parse() calls
-- raise "attempt to yield across C-call boundary" (neovim#33277); parse synchronously.
vim.g._ts_force_sync_parsing = true
vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.g.loaded_perl_provider = 0 -- unused; Guix has no Neovim::Ext
vim.g.loaded_node_provider = 0 -- unused by current plugins
vim.g.loaded_ruby_provider = 0
vim.o.number = true
vim.o.relativenumber = true
vim.o.cursorline = true
vim.o.signcolumn = "yes"
vim.o.termguicolors = true
vim.opt.clipboard = "unnamedplus" -- system clipboard (xclip / wl-copy)
vim.cmd.colorscheme("h4ck3r")

-- user-level tool dirs (npm/cargo/go/uv installs)
for _, d in ipairs({ "~/.local/bin", "~/.cargo/bin", "~/go/bin" }) do
  d = vim.fn.expand(d)
  if not vim.env.PATH:find(d, 1, true) then vim.env.PATH = d .. ":" .. vim.env.PATH end
end

-- llama.vim: FIM ghost-text autocomplete via the same local llama-server as
-- CodeCompanion (~/.local/bin/llama-local, 127.0.0.1:8080). Silent if it is down.
vim.g.llama_config = {
  endpoint_fim = "http://127.0.0.1:8080/infill",
  endpoint_inst = "http://127.0.0.1:8080/v1/chat/completions",
  show_info = 0,
}

-- Native package manager (Neovim 0.12)
vim.pack.add({
  "https://github.com/nvim-lua/plenary.nvim",
  { src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main" }, -- master is incompatible with 0.12
  "https://github.com/olimorris/codecompanion.nvim",
  "https://github.com/ggml-org/llama.vim",
  "https://github.com/neovim/nvim-lspconfig",
  "https://github.com/stevearc/conform.nvim",
  "https://github.com/mfussenegger/nvim-lint",
  "https://github.com/mfussenegger/nvim-dap",
  "https://github.com/nvim-neotest/nvim-nio",
  "https://github.com/rcarriga/nvim-dap-ui",
  "https://github.com/theHamsta/nvim-dap-virtual-text",
  "https://github.com/mfussenegger/nvim-dap-python",
  { src = "https://github.com/saghen/blink.cmp", version = vim.version.range("1") },
  "https://github.com/hat0uma/csvview.nvim",
  "https://github.com/Olical/conjure",
  "https://github.com/MeanderingProgrammer/render-markdown.nvim",
  "https://github.com/nvim-orgmode/orgmode",
  "https://github.com/nvim-tree/nvim-web-devicons",
  "https://github.com/lewis6991/gitsigns.nvim",
  "https://github.com/sindrets/diffview.nvim",
  "https://github.com/NeogitOrg/neogit",
  "https://github.com/ibhagwan/fzf-lua",
  { src = "https://github.com/nvim-treesitter/nvim-treesitter-textobjects", version = "main" },
  "https://github.com/pwntester/octo.nvim",
  "https://github.com/folke/which-key.nvim",
  "https://github.com/MunifTanjim/nui.nvim",
  { src = "https://github.com/nvim-neo-tree/neo-tree.nvim", version = "v3.x" },
}, { confirm = false })
-- headlines.nvim is only used for org: keep it off the runtimepath until an
-- org buffer opens, so it never touches markdown (render-markdown owns that)
vim.pack.add({ "https://github.com/lukas-reineke/headlines.nvim" },
  { confirm = false, load = function() end })

local ok, cc = pcall(require, "codecompanion")
if ok then
  cc.setup({
    adapters = {
      http = {
        opts = { show_defaults = false },
        llamacpp = function()
          return require("codecompanion.adapters").extend("openai_compatible", {
            name = "llamacpp",
            formatted_name = "llama.cpp",
            env = { url = "http://127.0.0.1:8080", api_key = "none",
                    chat_url = "/v1/chat/completions", models_endpoint = "/v1/models" },
            schema = { model = { default = "local" } },
          })
        end,
      },
    },
    strategies = {
      chat = { adapter = "llamacpp" },
      inline = { adapter = "llamacpp" },
      cmd = { adapter = "llamacpp" },
    },
  })
end

local map = vim.keymap.set
-- AI keys: check the local llama-server first (1 s) so a dead server gives a
-- short notice instead of a long timeout + traceback; offer to start it.
local function llm_up()
  local r = vim.system({ "curl", "-s", "-m", "1", "http://127.0.0.1:8080/health" }, { text = true }):wait()
  return r.code == 0 and (r.stdout or ""):find('"ok"') ~= nil
end
local function with_llm(cmd)
  return function()
    if llm_up() then return vim.cmd(cmd) end
    vim.notify("llama-server is not running on :8080 — starting it (llama-local start); try again in a few seconds",
      vim.log.levels.WARN)
    vim.system({ "sh", "-c", "LLAMA_NOWAIT=1 llama-local start >/dev/null 2>&1" }, { detach = true })
  end
end
map({ "n", "v" }, "<leader>ac", with_llm("CodeCompanionChat Toggle"), { desc = "AI chat toggle" })
map({ "n", "v" }, "<leader>ai", function()
  if llm_up() then return vim.api.nvim_feedkeys(":CodeCompanion ", "n", false) end
  with_llm("")()
end, { desc = "AI inline prompt" })
map({ "n", "v" }, "<leader>aa", with_llm("CodeCompanionActions"), { desc = "AI actions" })

for _, m in ipairs({ "ui", "treesitter", "completion", "lsp", "format", "lint", "dap", "extras", "notes", "keys", "tree", "git", "finder" }) do
  local okm, err = pcall(require, "config." .. m)
  if not okm then vim.notify(m .. ": " .. tostring(err), vim.log.levels.WARN) end
end
