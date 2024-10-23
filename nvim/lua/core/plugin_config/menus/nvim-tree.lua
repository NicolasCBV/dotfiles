local status_ok, tree = pcall(require, "nvim-tree")
if not status_ok then
  M.deps.nvim_tree = { package = nil, name = 'nvim-tree' }
  return
end

local HEIGHT_RATIO = 0.8
local WIDTH_RATIO = 0.5

tree.setup({
  disable_netrw = true,
  hijack_netrw = true,
  respect_buf_cwd = true,
  sync_root_with_cwd = true,
  git = {
    enable = true,
    ignore = false,
    timeout = 500,
  },
  view = {
    float = {
      enable = true,
      open_win_config = function()
        local screen_w = vim.opt.columns:get()
        local screen_h = vim.opt.lines:get() - vim.opt.cmdheight:get()
        local window_w = screen_w * WIDTH_RATIO
        local window_h = screen_h * HEIGHT_RATIO
        local window_w_int = math.floor(window_w)
        local window_h_int = math.floor(window_h)
        local center_x = (screen_w - window_w) / 2
        local center_y = ((vim.opt.lines:get() - window_h) / 2)
                         - vim.opt.cmdheight:get()
        return {
          border = "rounded",
          relative = "editor",
          row = center_y,
          col = center_x,
          width = window_w_int,
          height = window_h_int,
        }
        end,
    },
    width = function()
      return math.floor(vim.opt.columns:get() * WIDTH_RATIO)
    end,
  },
})

M.keys.add({
  {
    shortcut = '<C-b>',
    cmd = ':NvimTreeOpen<CR>',
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

M.deps.nvim_tree = { package = tree, name = 'nvim-tree' }
