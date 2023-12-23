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
    cmd = ":lua require'dap'.clear_breakpoints()<CR>",
    desc = 'Clear breakpoints (dap)'
  },
  {
    shortcut = '<F5>',
    cmd = ":lua require'dap'.continue()<cr>",
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
    cmd = ":lua require'dap'.toggle_breakpoint()<CR>",
    desc = 'Toggle breakpoint (dap)'
  },
  {
    shortcut = '<leader>dd',
    cmd = ":lua require'dap'.disconnect()<CR>",
    desc = 'Disconnect (dap)'
  }
})
