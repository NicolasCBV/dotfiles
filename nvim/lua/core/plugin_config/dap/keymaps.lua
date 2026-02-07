M.keys.add({
  {
    shortcut = '<leader>sb',
    cmd = M.deps.dap.fn.run_spring_boot,
    desc = 'Run spring boot'
  },
  {
    shortcut = '<leader>sd',
    cmd = function() M.deps.dap.fn.run_spring_boot(true) end,
    desc = 'Run spring boot in debug mode'
  },
  {
    shortcut = '<F2>',
    cmd = function() M.deps.dap.package.clear_breakpoints() end,
    desc = 'Clear breakpoints (dap)'
  },
  {
    shortcut = '<F5>',
    cmd = M.deps.dap.fn.dap_continue,
    desc = 'Continue (dap)'
  },
  {
    shortcut = '<F3>',
    cmd = ':DapTerminate<CR>',
    desc = 'Teminate (dap)'
  },
  {
    shortcut = '<F7>',
    cmd = ':DapStepInto<CR>',
    desc = 'Step into (dap)'
  },
  {
    shortcut = '<F8>',
    cmd = ':DapStepOut<CR>',
    desc = 'Step out (dap)'
  },
  {
    shortcut = '<F9>',
    cmd = ':DapStepOver<CR>',
    desc = 'Step over (dap)'
  },
  {
    shortcut = '<leader>b',
    cmd = M.deps.dap.package.toggle_breakpoint,
    desc = 'Toggle breakpoint (dap)'
  },
  {
    shortcut = '<leader>dd',
    cmd = M.deps.dap.package.disconnect,
    desc = 'Disconnect (dap)'
  }
})
