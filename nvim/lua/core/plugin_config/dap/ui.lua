local status_ok, dapui = pcall(require, "dapui")
if not status_ok or not M.deps.dap.package then
  M.deps.dapui = { package = nil, name = 'dapui' }
  return
end

dapui.setup({
  icons = { expanded = "▾", collapsed = "▸", current_frame = "▸" },
  mappings = {
    expand = { "<CR>", "<2-LeftMouse>" },
    open = "o",
    remove = "d",
    edit = "e",
    repl = "r",
    toggle = "t",
  },
  expand_lines = false,
  layouts = {
    {
      elements = {
        { id = "repl", size = 0.15 },
        "console",
        "stack",
        "watches",
        "breakpoints",
      },
      size = 40,
      position = "left",
    },
    {
      elements = {
        "scopes",
      },
      size = 0.25,
      position = "bottom",
    },
  },
  floating = {
    max_height = nil, -- These can be integers or a float between 0 and 1.
    max_width = nil, -- Floats will be treated as percentage of your screen.
    border = "rounded", -- Border style. Can be "single", "double" or "rounded"
    mappings = {
      close = { "q", "<Esc>" },
    },
  },
  windows = { indent = 1 },
  render = {
    max_type_length = nil, -- Can be integer or nil.
    max_value_lines = 100, -- Can be integer or nil.
  }
})

M.deps.dap.package.listeners.after.event_initialized["dapui_config"]=function()
  dapui.open()
end
M.deps.dap.package.listeners.before.event_terminated["dapui_config"]=function()
  dapui.close()
end
M.deps.dap.package.listeners.before.event_exited["dapui_config"]=function()
  dapui.close()
end

vim.fn.sign_define('DapBreakpoint',{ text = '', texthl ='', linehl ='', numhl =''})

M.keys.add({
  {
    shortcut = '<leader>dq',
    cmd = ":DapUiToggle<CR>",
    desc = "Open UI (dapui)"
  },
  {
    shortcut = '<leader>dw',
    cmd = ':lua require("dapui").open({ reset = true })<CR>',
    desc = 'Open UI with reset as true (dapui)'
  },
  {
    shortcut = '<leader>dq',
    cmd = ':lua require("dapui").close()<CR>',
    desc = 'Close UI (dapui)'
  }
})

M.deps.dapui = { package = dapui, name = 'dapui' }
