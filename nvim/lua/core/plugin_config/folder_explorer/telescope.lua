local status_ok, builtin = pcall(require, "telescope.builtin")
if not status_ok then
  M.deps.telescope_builtin = { package = nil, name = 'telescope.builtin' }
  return
end

M.keys.add({
  {
    shortcut = '<C-p>',
    cmd = builtin.find_files,
    desc = 'Search for files'
  },
  {
    shortcut = '<Space><Space>',
    cmd = builtin.oldfiles,
    desc = 'Search for old files'
  },
  {
    shortcut = '<Space>fh',
    cmd = builtin.help_tags,
    desc = 'Search for help tags'
  },
  {
    shortcut = '<C-g>',
    cmd = builtin.live_grep,
    desc = 'Search with live grep'
  },
  {
    shortcut = '<leader>fb',
    cmd = builtin.buffers,
    desc = 'Search with buffers'
  }
})

M.deps.telescope_builtin = { package = builtin, name = 'telescope.builtin' }
