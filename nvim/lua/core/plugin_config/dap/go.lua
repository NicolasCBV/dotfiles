local status_ok, dap_go = pcall(require, "dap-go")
if not status_ok then
  M.deps.dap_go = { package = nil, name = "dap-go" }
  return
end

dap_go.setup({
  dap_configurations = {
    {
      type = "go",
      name = "Attach remote",
      mode = "remote",
      request = "attach"
    },
    {
      name = "------ Launch.json configs ------",
      type = "",
      request = "launch"
    }
  },
  delve = {
    path = "dlv",
    initialize_timeout_sec = 20,
    port = "${port}",
    args = {},
    build_flags = {},
    detached = vim.fn.has("win32") == 0,
    cwd = nil,
  },
  tests = {
    verbose = false,
  },
})

M.deps.dap_go = { package = dap_go, name = "dap-go" }
