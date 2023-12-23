local status_ok, gruvbox = pcall(require, "gruvbox")
if not status_ok then
   M.deps.gruvbox = { package = nil, name = 'gruvbox' }
   return
end
gruvbox.setup({
   palette_overrides = {
     gray = "#2ea542"
   }
})
vim.o.background = "dark"
vim.cmd([[colorscheme gruvbox]])

M.deps.gruvbox = { package = gruvbox, name = 'gruvbox' }
