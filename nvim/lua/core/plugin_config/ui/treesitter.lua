local status_ok, treesitter = pcall(require, 'nvim-treesitter.configs')
if not status_ok then
    M.deps.treesitter = { package = nil, name = 'nvim-treesitter' }
    return
end

treesitter.setup({
	ensure_installed = {'javascript', 'typescript', 'html', 'css', 'tsx', 'java'},
    sync_install = false,
    auto_install = true,
    autotag = {
        enable = true,
    },
    highlight = {
		enable = true,
	}
})

M.deps.treesitter = { package = treesitter, name = 'nvim-treesitter' }
