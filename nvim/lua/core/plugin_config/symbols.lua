local status_ok, symbols = pcall(require, "symbols-outline")
if not status_ok then
  M.deps.symbols_outline = { package = nil, name = 'symbols-outline' }
  return
end

symbols.setup({
  auto_close = true,
})

M.keys.add({{
  shortcut = '<leader><leader>',
  cmd = ':SymbolsOutline<CR>',
  desc = 'Toggle symbols'
}})

M.deps.symbols_outline = { package = symbols, name = 'symbols-outline' }
