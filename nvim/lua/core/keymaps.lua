M.keys = { list = {} }

local function nnoremap(rhs, lhs, bufopts, desc)
  local opts = bufopts or {}
  opts.desc = desc or "Description wasn't defined"
  vim.keymap.set("n", rhs, lhs, opts)
end

M.keys.add = function(newKeys)
  for i=1, #newKeys do
    M.keys.list[#M.keys.list + 1] = newKeys[i]
  end
end

M.keys.parse = function()
  if #M.keys.list ~= 0 then
    for _, key in ipairs(M.keys.list) do
      nnoremap(key.shortcut, key.cmd, key.opts, key.desc)
    end
  end
end

local globalOpt = { silent=true  }

M.keys.add({
  {
    shortcut = '<C-t>',
    cmd = ':vertical new<CR>',
    opts = globalOpt,
    desc = 'Open new vertical window'
  },
  {
    shortcut = '<C-s>',
    cmd = ':w<CR>',
    opts = globalOpt,
    desc = 'Write file'
  },
  {
    shortcut = '<C-z>',
    cmd = ':undo<CR>',
    opts = globalOpt,
    desc = 'Undo file modifications'
  },
  {
    shortcut = '<C-y>',
    cmd = ':redo<CR>',
    opts = globalOpt,
    desc = 'Redo file modifications'
  },
  {
    shortcut = '<C-q>',
    cmd = ':qa<CR>',
    opts = globalOpt,
    desc = 'Close all files'
  },
  {
    shortcut = '<C-Up>',
    cmd = ':m -2<CR>',
    opts = { noremap = true, silent = true },
    desc = 'Move up 1 line'
  },
  {
    shortcut = '<C-Down>',
    cmd = ':m +1<CR>',
    opts = { noremap = true, silent = true },
    desc = 'Move down 1 line'
  },
})

vim.api.nvim_set_keymap('v', '<C-Up>', ':m .-2<CR>gv=gv', { noremap = true, silent = true })
vim.api.nvim_set_keymap('v', '<C-Down>', ":m '>+1<CR>gv=gv", { noremap = true, silent = true })
vim.api.nvim_set_keymap('v', '<C-Right>', ":'<,'>><CR>gv", { noremap = true, silent = true })
vim.api.nvim_set_keymap('v', '<C-Left>', ":'<,'><<CR>gv", { noremap = true, silent = true })


return M
