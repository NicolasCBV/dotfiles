local status_ok_dap, dap = pcall(require, 'dap')
if not status_ok_dap then
  M.deps.dap = {
    package = nil,
    name = 'dap',
    fn = {},
    internals = nil
  }
  return
end

dap.set_log_level('TRACE')

local status_ok_ext_vscode, dap_ext_vscode = pcall(require, 'dap.ext.vscode')
if not status_ok_ext_vscode then
  M.deps.dap = {
    package = dap,
    name = 'dap',
    internals = {
      { module = nil, name = 'dap.ext.vscode' }
    }
  }
end

dap_ext_vscode.load_launchjs()

M.deps.dap = {
  package = dap,
  name = 'dap',
  fn = {},
  internals = {
    { module = dap_ext_vscode, name = 'dap.ext.vscode' }
  }
}

