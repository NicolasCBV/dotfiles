local status_ok, neotree = pcall(require, "neo-tree")
if not status_ok then
  M.deps.neotree = { package = nil, name = 'neo-tree' }
  return
end

neotree.setup({
    popup_border_style = "rounded",
    enable_git_status = true,
    enable_diagnostics = true,
    default_component_configs = {
      indent = {
        padding = 0
      },
      git_status = {
        symbols = {
          added = "+",
          modified = "",
          deleted = "✖",
          renamed = "",
          untracked = "",
          ignored = "",
          staged = "",
          conflict = "",
        }
      }
    },
    filesystem = {
      window = {
        position = "float",
        width = 25
      }
    }
})

M.keys.add({
  {
    shortcut = '<C-b>',
    cmd = ':Neotree<CR>',
    opts = { silent = true }
  },
  {
    shortcut = '<S-left>',
    cmd = '<Cmd>BufferPrevious<CR>',
    opts = { silent = true }
  },
  {
    shortcut = '<S-c>',
    cmd = ':close<CR>',
    opts = { silent = true }
  },
  {
    shortcut = '<S-right>',
    cmd = '<Cmd>BufferNext<CR>',
    opts = { silent = true }
  },
  {
    shortcut = '<S-q>',
    cmd = '<Cmd>BufferClose<CR>',
    opts = { silent = true }
  },
  {
    shortcut = '<S-p>',
    cmd = '<Cmd>BufferPin<CR>',
    opts = { silent = true }
  }
})

M.deps.neotree = { package = neotree, name = 'neo-tree' }
