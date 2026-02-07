local status_ok, dap_go = pcall(require, "dap-go")
if not status_ok then
  M.deps.dap_go = { package = nil, name = "dap-go" }
  return
end

dap_go.setup({
  dap_configurations = {
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

M.deps.dap.package.adapters.go_remote  = {
  type = "server",
  host = "127.0.0.1",
  port = 4444
}

local Config = {}
function Config:new()
  local config = {
    type = 'go_remote',
    request = 'attach',
    name = 'Attach remote (Docker)',
    mode = 'remote',
    substitutePath = { {
        from = "${workspaceFolder}",
        to = "/home/app"
    } },
    connect = function()
      local host = vim.fn.input("Host: [127.0.0.1]: ")
      host = host ~= "" and host or "127.0.0.1"
      local port = tonumber(vim.fn.input("Port [4444]: ")) or 4444

      return { host = host, port = port }
    end
  }

  setmetatable(config, self)
  self.__index = self
  return config
end

function Config:setSubstitutePath(path)
  self.substitutePath = {{
    from = "${workspaceFolder}",
    to = path
  }}
end

local go_config = Config:new()

table.insert(M.deps.dap.package.configurations.go, go_config)

M.deps.dap_go = { package = dap_go, name = "dap-go" }
