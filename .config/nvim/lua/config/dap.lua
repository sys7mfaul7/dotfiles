local ok, dap = pcall(require, "dap")
if not ok then return end
local dapui = require("dapui")
dapui.setup({ floating = { border = "rounded" } })
require("nvim-dap-virtual-text").setup({})
dap.listeners.after.event_initialized["dapui"] = function() dapui.open() end
dap.listeners.before.event_terminated["dapui"] = function() dapui.close() end
dap.listeners.before.event_exited["dapui"] = function() dapui.close() end
vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "DapBreakpoint" })
vim.fn.sign_define("DapStopped", { text = "▶", texthl = "DapStopped", linehl = "DapStoppedLine" })

local function prog()
  return vim.fn.input("Executable: ", vim.fn.getcwd() .. "/", "file")
end
-- C/C++/Rust: lldb-dap (Guix lldb); gdb >= 14 native DAP as alternative
if vim.fn.executable("lldb-dap") == 1 then
  dap.adapters.lldb = { type = "executable", command = "lldb-dap", name = "lldb" }
end
if vim.fn.executable("gdb") == 1 then
  dap.adapters.gdb = { type = "executable", command = "gdb", args = { "--interpreter=dap", "--eval-command", "set print pretty on" } }
end
local native = {
  { name = "Launch (lldb)", type = "lldb", request = "launch", program = prog, cwd = "${workspaceFolder}", stopOnEntry = false, args = {} },
  { name = "Launch (gdb)", type = "gdb", request = "launch", program = prog, cwd = "${workspaceFolder}", stopAtBeginningOfMainSubprogram = false },
  { name = "Attach (lldb)", type = "lldb", request = "attach", pid = require("dap.utils").pick_process },
}
dap.configurations.c = native; dap.configurations.cpp = native; dap.configurations.rust = native
-- Python: debugpy
local okp, dpy = pcall(require, "dap-python")
if okp then dpy.setup("python3") end
-- Go: delve
if vim.fn.executable("dlv") == 1 then
  dap.adapters.delve = { type = "server", port = "${port}",
    executable = { command = "dlv", args = { "dap", "-l", "127.0.0.1:${port}" } } }
  dap.configurations.go = {
    { type = "delve", name = "Debug file", request = "launch", program = "${file}" },
    { type = "delve", name = "Debug package", request = "launch", program = "${fileDirname}" },
    { type = "delve", name = "Debug test", request = "launch", mode = "test", program = "${file}" },
  }
end
local m = vim.keymap.set
m("n", "<F5>", dap.continue, { desc = "Debug continue/start" })
m("n", "<F10>", dap.step_over, { desc = "Step over" })
m("n", "<F11>", dap.step_into, { desc = "Step into" })
m("n", "<F12>", dap.step_out, { desc = "Step out" })
m("n", "<leader>b", dap.toggle_breakpoint, { desc = "Toggle breakpoint" })
m("n", "<leader>B", function() dap.set_breakpoint(vim.fn.input("Condition: ")) end, { desc = "Conditional breakpoint" })
m("n", "<leader>du", dapui.toggle, { desc = "DAP UI" })
m("n", "<leader>dr", dap.repl.toggle, { desc = "DAP REPL" })
m("n", "<leader>dq", dap.terminate, { desc = "DAP terminate" })
