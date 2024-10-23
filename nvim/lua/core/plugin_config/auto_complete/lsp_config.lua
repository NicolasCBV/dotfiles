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
    "gopls",
    "tailwindcss",
    "clangd",
    "html",
    "cssls",
    "csharp_ls",
    "angularls",
    "jdtls",
    "lua_ls",
    "omnisharp",
    "omnisharp_mono",
    "tsserver",
    "dockerls",
    "terraformls"
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

local on_attach = function(_, bufnr)
  local opts = { buffer = bufnr }
  nnoremap(
    "<leader><Enter>",
    vim.lsp.buf.type_definition,
    opts,
    "Type definition"
  )
  nnoremap("<leader>ca", vim.lsp.buf.code_action, opts, "Code action")
  nnoremap("gd", vim.lsp.buf.definition, opts, "Definition")
  nnoremap("gr",  M.deps.telescope_builtin.package.lsp_references, opts, "Lsp references (telescope)")
  nnoremap(
    "<leader>rr",
    function ()
      vim.diagnostic.reset();
      vim.cmd('LspRestart');
    end,
    opts,
    "Restart LSP"
  )
end

lsp.gopls.setup {
  capabilities = capabilities,
  on_attach = on_attach
}

lsp.rust_analyzer.setup {
  capabilities = capabilities,
  on_attach = on_attach,
  ignore = { "dist/**", "build/**", "target/**" },
  cmd = {
    "rustup", "run", "stable", "rust-analyzer"
  }
}

lsp.terraformls.setup {
  capabilities = capabilities,
  on_attach = on_attach
}

lsp.html.setup {
  capabilities = capabilities,
  on_attach = on_attach,
}

lsp.cssls.setup {
  capabilities = capabilities,
  on_attach = on_attach,
}

lsp.dockerls.setup {
  capabilities = capabilities,
  on_attach = on_attach,
}

lsp.angularls.setup {
  capabilities = capabilities,
  on_attach = on_attach,
  root_dir = lsp.util.root_pattern("package.json"),
  ignore = { "node_modules/**", "dist/**", "build/**", ".angular/**" }
}

lsp.tailwindcss.setup {
  capabilities = capabilities,
  on_attach = on_attach,
  root_dir = lsp.util.root_pattern("package.json"),
  ignore = { "node_modules/**", "dist/**", "build/**" }
}


lsp.omnisharp.setup {
  capabilities = capabilities,
  on_attach = on_attach,
  ignore = { "dist/**", "build/**" }
}

lsp.lua_ls.setup {
  capabilities = capabilities,
  on_attach = on_attach,
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
  capabilities = capabilities,
  on_attach = on_attach,
  ignore = { "dist/**", "build/**" }
}

lsp.tsserver.setup {
  capabilities = capabilities,
  on_attach = on_attach,
  filetypes = { "typescript", "javascript", "typescriptreact", "javascriptreact" },
  root_dir = lsp.util.root_pattern("package.json"),
  ignore = { "node_modules/**", "dist/**", "build/**" },
}

M.deps.cmp_nvim_lsp = { package = cmp_nvim_lsp, name = 'cmp_nvim_lsp' }
M.deps.lspconfig = { package = lsp, name = 'lspconfig' }
