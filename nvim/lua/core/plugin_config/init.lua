M.deps = {}

require("core.plugin_config.telescope")
require("core.plugin_config.auto-pairs")
require("core.plugin_config.completions")
require("core.plugin_config.gruvbox")
require("core.plugin_config.lsp_config")
require("core.plugin_config.lualine")
require("core.plugin_config.neo-tree")
require("core.plugin_config.nvim_comment")
require("core.plugin_config.toggleterm")
require("core.plugin_config.treesitter")
require("core.plugin_config.errors")
require("core.plugin_config.dap.init")
require("core.plugin_config.symbols")
require("core.plugin_config.folding")

for _, dep in pairs(M.deps) do
  local function buildErrorMsg(dep_name)
    local error_msg =
      'Looks like '
      .. dep_name ..
      ' is being manipulated by neovim, but no installation folder was found!'

      return error_msg
  end

  if not dep.package then
    local error_msg = buildErrorMsg(dep.name)
    vim.api.nvim_err_writeln(error_msg)
  end

  if dep.internals then
    for _, internal_pack in pairs(dep.internals) do
      if not internal_pack.module then
        local error_msg = buildErrorMsg(internal_pack.name)
        vim.api.nvim_err_writeln(error_msg)
      end
    end
  end
end
