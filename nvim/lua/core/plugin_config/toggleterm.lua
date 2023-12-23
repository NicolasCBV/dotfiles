local status_ok, toggleterm = pcall(require, "toggleterm")
if not status_ok then
	M.deps.toggleterm = { package = nil, name = 'toggleterm' }
	return
end

toggleterm.setup({
	open_mapping = [[<C-n>]],
	hide_numbers = true,
	persist_size = true,
	close_on_exit = true,
	shell = vim.o.shell,
	direction = "float",
    shade_terminals = false
})

M.deps.toggleterm = { package = toggleterm, name = 'toggleterm' }

