M.utils = M.utils or {}
M.utils.lsp = {}

local cmp_status_ok, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
if not cmp_status_ok or not M.deps.telescope_builtin.package then
  M.deps.cmp_nvim_lsp = { package = nil, name ="cmp_nvim_lsp" }
  return
end

M.utils.lsp.capabilities = cmp_nvim_lsp.default_capabilities()

local util_ok, util = pcall(require, "lspconfig.util")

M.utils.lsp.find_project_root = function(fname)
  fname = fname or vim.api.nvim_buf_get_name(0)
  local start_dir = (fname ~= "" and fname) and vim.fn.fnamemodify(fname, ":p:h") or vim.loop.cwd()

  if util_ok and util and util.search_ancestors then
    local root = util.search_ancestors(start_dir, function(path)
      if vim.fn.filereadable(path .. "/pnpm-workspace.yaml") == 1 then return path end
      if vim.fn.filereadable(path .. "/lerna.json") == 1 then return path end

      local pj = path .. "/package.json"
      if vim.fn.filereadable(pj) == 1 then
        local ok, lines = pcall(vim.fn.readfile, pj)
        if ok and lines then
          local content = table.concat(lines, "\n")
          if content:match('"workspaces"%s*:') then
            return path
          end
        end
      end

      if vim.fn.isdirectory(path .. "/.git") == 1 then return path end

      return nil
    end)

    if root and root ~= "" then
      return root
    end
  end

  local dir = start_dir
  while dir ~= "/" and dir ~= "" do
    if vim.fn.filereadable(dir .. "/package.json") == 1 or 
       vim.fn.isdirectory(dir .. "/.git") == 1 then
      return dir
    end
    local parent = vim.fn.fnamemodify(dir, ":h")
    if parent == dir then break end
    dir = parent
  end

  return vim.loop.cwd()
end

local function nnoremap(rhs, lhs, bufopts, desc)
  bufopts.desc = desc
  vim.keymap.set("n", rhs, lhs, bufopts)
end

M.utils.lsp.on_attach = function(_, bufnr)
  local opts = { buffer = bufnr }
  nnoremap("<leader><Enter>", vim.lsp.buf.type_definition, opts, "Type definition")
  nnoremap("<leader>ca", vim.lsp.buf.code_action, opts, "Code action")
  nnoremap("gd", vim.lsp.buf.definition, opts, "Definition")
  nnoremap("gr", M.deps.telescope_builtin.package.lsp_references, opts, "Lsp references (telescope)")
  nnoremap(
    "<leader>rr",
    function()
      vim.diagnostic.reset()
      vim.cmd('LspRestart')
    end,
    opts,
    "Restart LSP"
  )
end

local function get_vue_langserver_path()
  local mason_pkg = vim.fn.stdpath('data') .. '/mason/packages/vue-language-server'
  local candidate = mason_pkg .. '/node_modules/@vue/language-server'
  if vim.fn.isdirectory(candidate) == 1 then
    return candidate
  end
  if vim.env.MASON then
    local p = vim.env.MASON .. '/packages/vue-language-server/node_modules/@vue/language-server'
    if vim.fn.isdirectory(p) == 1 then return p end
  end
  return nil
end

M.utils.lsp.vue_language_server_path = get_vue_langserver_path()
