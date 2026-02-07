M.deps = {}

require("core.plugin_config.nui.init")
require("core.plugin_config.utils.init")

require("core.plugin_config.folder_explorer.telescope")
require("core.plugin_config.auto_complete.auto-pairs")
require("core.plugin_config.auto_complete.nvim_comment")
require("core.plugin_config.completions.completions")
require("core.plugin_config.theme.github")
require("core.plugin_config.auto_complete.lsp_config")
require("core.plugin_config.ui.lualine")
require("core.plugin_config.menus.nvim-tree")
require("core.plugin_config.terminal.toggleterm")
require("core.plugin_config.ui.treesitter")
require("core.plugin_config.code_errors.errors")
require("core.plugin_config.dap.init")

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
