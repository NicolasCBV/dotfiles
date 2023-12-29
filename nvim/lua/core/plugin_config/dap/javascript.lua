local status_ok, dap_vscode_js = pcall(require, 'dap-vscode-js')
if not status_ok then
  M.deps.dap_vscode_js = { package = nil, name = 'dap-vscode-js' }
  return
end

dap_vscode_js.setup({
  adapters = { 'pwa-node', 'node-terminal', 'pwa-extensionHost' }
})

M.deps.dap.langs = {
  js_based_langs = {
    "typescript",
    "javascript",
    "typescriptreact",
    "javascriptreact"
  }
}

for _, lang in ipairs(M.deps.dap.langs.js_based_langs) do
  M.deps.dap.package.configurations[lang] = {
    {
      type = "pwa-node",
      request = "launch",
      name = "Launch file",
      program = "${file}",
      cwd = "${workspaceFolder}",
      sourceMaps = true
    },
    {
      type = "pwa-node",
      request = "attach",
      name = "Attach",
      processId = require'dap.utils'.pick_process,
      cwd = "${workspaceFolder}",
      sourceMaps = true
    },
    {
      name = "------ Launch.json configs ------",
      type = "",
      request = "launch"
    }
  }
end

M.deps.dap_vscode_js = { package = dap_vscode_js, name = 'dap-vscode-js' }
