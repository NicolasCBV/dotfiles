require("core.plugin_config.auto_complete.utils")

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
    "jdtls",
    "lua_ls",
    "omnisharp",
    "dockerls",
    "terraformls",
    "ts_ls",
    "vue_ls",
  }
})

M.deps.mason = { package = mason, name = 'mason' }
M.deps.masonlsp = { package = masonlsp, name = 'mason-lspconfig' }

local lsp = vim.lsp.config
lsp("ts_ls", {
  capabilities = M.utils.lsp.capabilities,
  on_attach = M.utils.lsp.on_attach,
  filetypes = { "typescript", "javascript", "typescriptreact", "javascriptreact", "vue" },
  -- root_dir = M.utils.lsp.find_project_root,
  ignore = { "node_modules/**", "dist/**", "build/**" },
  init_options = {
    plugins = {
      {
        name = "@vue/typescript-plugin",
        location = M.utils.lsp.vue_language_server_path,
        languages = { "vue" }
      }
    }
  }
})

lsp("gopls", {
  capabilities = M.utils.lsp.capabilities,
  on_attach = M.utils.lsp.on_attach,
  root_dir = M.utils.lsp.find_project_root,
})

lsp("rust_analyzer", {
  capabilities = M.utils.lsp.capabilities,
  on_attach = M.utils.lsp.on_attach,
  root_dir = M.utils.lsp.find_project_root,
  cmd = { "rustup", "run", "stable", "rust-analyzer" }
})

lsp("terraformls", {
  capabilities = M.utils.lsp.capabilities,
  on_attach = M.utils.lsp.on_attach,
  root_dir = M.utils.lsp.find_project_root,
})

lsp("html", {
  capabilities = M.utils.lsp.capabilities,
  on_attach = M.utils.lsp.on_attach,
  root_dir = M.utils.lsp.find_project_root,
})

lsp("cssls", {
  capabilities = M.utils.lsp.capabilities,
  on_attach = M.utils.on_attach,
  root_dir = M.utils.find_project_root,
})

lsp("dockerls", {
  capabilities = M.utils.lsp.capabilities,
  on_attach = M.utils.lsp.on_attach,
  root_dir = M.utils.lsp.find_project_root,
})

lsp("omnisharp", {
  capabilities = M.utils.lsp.capabilities,
  on_attach = M.utils.lsp.on_attach,
  root_dir = M.utils.lsp.find_project_root,
})

lsp("lua_ls", {
  capabilities = M.utils.lsp.capabilities,
  on_attach = M.utils.lsp.on_attach,
  root_dir = M.utils.lsp.find_project_root,
  filetypes = { "lua" },
  settings = {
    Lua = {
      diagnostics = {
        globals = { 'vim' }
      }
    }
  }
})

lsp("clangd", {
  capabilities = M.utils.lsp.capabilities,
  on_attach = M.utils.lsp.on_attach,
  ignore = { "dist/**", "build/**", "cache/**" },
})
