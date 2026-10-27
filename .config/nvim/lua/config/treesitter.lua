-- nvim-treesitter `main` branch (the `master` branch is not compatible with Neovim 0.12:
-- its query predicates throw "attempt to call method 'range'" and break markdown injections).
-- main only installs parsers/queries (into ~/.local/share/nvim/site); highlighting and
-- indentation are started per buffer below. Update parsers with :TSUpdate.
local ok, ts = pcall(require, "nvim-treesitter")
if not ok then return end

local langs = { "c", "cpp", "rust", "python", "lua", "luadoc", "java", "go", "gomod", "gosum",
  "ruby", "commonlisp", "scheme", "json", "jq", "html", "css", "xml", "csv", "tsv",
  "powershell", "bash", "asm", "nasm", "markdown", "markdown_inline", "yaml", "toml", "vim",
  "vimdoc", "query", "javascript", "typescript", "bicep", "regex", "make", "cmake" }

-- Install only what is missing (no-op otherwise; runs async, no network if all present).
local have = {}
for _, l in ipairs(ts.get_installed()) do have[l] = true end
local missing = vim.tbl_filter(function(l) return not have[l] end, langs)
if #missing > 0 and #vim.api.nvim_list_uis() > 0 then ts.install(missing) end

-- Highlighting + (experimental) indentation for any filetype that has a parser.
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("user_treesitter", { clear = true }),
  callback = function(ev)
    local lang = vim.treesitter.language.get_lang(vim.bo[ev.buf].filetype)
    if not lang or not pcall(vim.treesitter.start, ev.buf, lang) then return end
    if lang ~= "markdown" and lang ~= "yaml" then
      vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end
  end,
})

-- Treesitter text objects (nvim-treesitter-textobjects, main branch)
local okt, tto = pcall(require, "nvim-treesitter-textobjects")
if okt then
  tto.setup({ select = { lookahead = true }, move = { set_jumps = true } })
  local sel = require("nvim-treesitter-textobjects.select")
  local mv = require("nvim-treesitter-textobjects.move")
  local map = vim.keymap.set
  for key, obj in pairs({ af = "@function.outer", ["if"] = "@function.inner", ac = "@class.outer",
      ic = "@class.inner", aa = "@parameter.outer", ia = "@parameter.inner" }) do
    map({ "x", "o" }, key, function() sel.select_textobject(obj, "textobjects") end, { desc = "TS " .. obj })
  end
  local moves = {
    ["]m"] = { "goto_next_start", "@function.outer", "Next function start" },
    ["]M"] = { "goto_next_end", "@function.outer", "Next function end" },
    ["[m"] = { "goto_previous_start", "@function.outer", "Prev function start" },
    ["[M"] = { "goto_previous_end", "@function.outer", "Prev function end" },
    ["]]"] = { "goto_next_start", "@class.outer", "Next class start" },
    ["]["] = { "goto_next_end", "@class.outer", "Next class end" },
    ["[["] = { "goto_previous_start", "@class.outer", "Prev class start" },
    ["[]"] = { "goto_previous_end", "@class.outer", "Prev class end" },
  }
  for key, m in pairs(moves) do
    map({ "n", "x", "o" }, key, function() mv[m[1]](m[2], "textobjects") end, { desc = m[3] })
  end
end
-- Incremental selection: Neovim 0.12 has it built in (visual an / in / ]n / [n, :h v_an);
-- these are just the familiar shortcuts on top of it
vim.keymap.set("n", "<C-space>", "van", { remap = true, desc = "Select treesitter node" })
vim.keymap.set("x", "<C-space>", "an", { remap = true, desc = "Expand selection (parent node)" })
vim.keymap.set("x", "<BS>", "in", { remap = true, desc = "Shrink selection (child node)" })
