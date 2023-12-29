local mason_status_ok, mason = pcall(require, "mason")
if not mason_status_ok then
  M.deps.mason = { package = nil, name = 'mason' }
  return
end

mason.setup()

local masonlsp_status_ok, masonlsp = pcall(require, "mason-lspconfig")
if not masonlsp_status_ok then
  M.deps.masonlsp = { package = nil, name = 'mason-lspconfig' }
  return
end

masonlsp.setup({
  ensure_installed = {
    "clangd",
    "csharp_ls",
    "jdtls",
    "lua_ls",
    "omnisharp",
    "omnisharp_mono",
    "rust_analyzer",
    "tsserver",
  }
})

M.deps.mason = { package = mason, name = 'mason' }
M.deps.masonlsp = { package = masonlsp, name = 'mason-lspconfig' }

local cmp_status_ok, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
if not cmp_status_ok or not M.deps.telescope_builtin.package then
  M.deps.cmp_nvim_lsp = { package = nil, name = 'cmp_nvim_lsp' }
  return
end

local capabilities = cmp_nvim_lsp.default_capabilities()

local lsp_status_ok, lsp = pcall(require, "lspconfig")
if not lsp_status_ok then
  M.deps.lspconfig = { package = nil, name = 'lspconfig' }
  return
end

local function nnoremap(rhs, lhs, bufopts, desc)
  bufopts.desc = desc
  vim.keymap.set("n", rhs, lhs, bufopts)
end

local on_attach = function (_, _)
  nnoremap(
    "<leader><Enter>",
    '<cmd>:lua vim.lsp.buf.type_definition()<CR>',
    {},
    "Type definition"
  )
  nnoremap("<leader>ca", '<cmd>:lua vim.lsp.buf.code_action()<CR>', {}, "Code action")
  nnoremap("gd", '<cmd>:lua vim.lsp.buf.definition()<CR>', {}, "Definition")
  nnoremap("gr",  M.deps.telescope_builtin.package.lsp_references, {}, "Lsp references (telescope)")
end

lsp.rust_analyzer.setup {
  on_attach = on_attach,
  capabilities = capabilities,
  ignore = { "dist/**", "build/**" }
}

lsp.omnisharp.setup {
  on_attach = on_attach,
  capabilities = capabilities,
  ignore = { "dist/**", "build/**" }
}

lsp.lua_ls.setup {
  on_attach = on_attach,
  capabilities = capabilities,
  filetypes = { "lua" },
  settings = {
    Lua = {
      diagnostics = {
        globals = { 'vim' }
      }
    }
  }
}

lsp.clangd.setup {
  on_attach = on_attach,
  capabilities = capabilities,
  ignore = { "dist/**", "build/**" }
}

lsp.tsserver.setup {
  on_attach = on_attach,
  capabilities = capabilities,
  root_dir = lsp.util.root_pattern("package.json"),
  ignore = { "node_modules/**", "dist/**", "build/**" },
  cmd = {
    os.getenv('HOME') .. '/.local/share/nvim/mason/bin/typescript-language-server',
    '--stdio',
    '--log-level=2'
  }
}

M.deps.cmp_nvim_lsp = { package = cmp_nvim_lsp, name = 'cmp_nvim_lsp' }
M.deps.lspconfig = { package = lsp, name = 'lspconfig' }
