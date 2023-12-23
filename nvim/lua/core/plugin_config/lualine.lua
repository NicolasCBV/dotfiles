local status_ok, lualine = pcall(require, 'lualine')
if not status_ok then
  M.deps.lualine = { package = nil, name = 'lualine' }
  return
end

lualine.setup {
  options = {
    icons_enabled = true,
    theme = 'gruvbox'
  },
  sections = {
    lualine_a = {'mode'},
    lualine_b = {'branch', 'diagnostics', 'filename'},
    lualine_c = { },
    lualine_x = { 'location', 'filetype' },
    lualine_z = { }
  },
}

M.deps.lualine = { package = lualine, name = 'lualine' }
