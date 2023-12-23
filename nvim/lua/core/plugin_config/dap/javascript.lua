local status_ok, dap_vscode_js = pcall(require, 'dap-vscode-js')
if not status_ok then
  M.deps.dap_vscode_js = { package = nil, name = 'dap-vscode-js' }
  return
end

dap_vscode_js.setup({
  adapters = { 'pwa-node', 'pwa-chrome', 'pwa-msedge', 'node-terminal', 'pwa-extensionHost' }
})

for _, lang in ipairs({ 'javascript', 'typescript' }) do
  M.deps.dap.package.configurations[lang] = {
    {
      type = "pwa-node",
      request = "launch",
      name = "Launch file",
      program = "${file}",
      cwd = "${workspaceFolder}",
    },
    {
      type = "pwa-node",
      request = "attach",
      name = "Attach",
      processId = require'dap.utils'.pick_process,
      cwd = "${workspaceFolder}",
    }
  }
end

M.deps.dap_vscode_js = { package = dap_vscode_js, name = 'dap-vscode-js' }
