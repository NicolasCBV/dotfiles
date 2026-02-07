M.deps.dap.package.adapters.codelldb  = {
  type = "server",
  port = "${port}",
  executable = {
    command = vim.fn.stdpath("data") .. "/mason/bin/codelldb",
    args = { "--port", "${port}" },
  }
}

M.deps.dap.langs.c_family = { "cpp", "c" }

