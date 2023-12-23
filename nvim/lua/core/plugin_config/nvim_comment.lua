local status_ok, nvim_comment = pcall(require, "nvim_comment")
if not status_ok then
    M.deps.nvim_comment = { package = nil, name = 'nvim_comment' }
    return
end

nvim_comment.setup({
    operator_mapping = "<leader>"
})

M.deps.nvim_comment = { package = nvim_comment, name = 'nvim_comment' }

