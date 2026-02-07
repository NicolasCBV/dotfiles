---@diagnostic disable: lowercase-global
local home = os.getenv('HOME')
local jdtls = require('jdtls')

local root_markers = {
  '.git',
  'mvnw',
  'gradlew',
  'pom.xml',
  'build.gradle',
}
local root_dir = require('jdtls.setup').find_root(root_markers)

local workspace_folder = home .. '/.local/share/java_workspaces/' .. vim.fn.fnamemodify(root_dir, ":p:h:t")
local path_to_lombok = vim.fn.stdpath('data') .. '/mason/packages/jdtls/lombok.jar'
local path_to_jar = vim.fn.stdpath('data') .. '/mason/packages/jdtls/plugins/org.eclipse.equinox.launcher_1.6.800.v20240304-1850.jar'

function nnoremap(rhs, lhs, bufopts, desc)
  bufopts.desc = desc
  vim.keymap.set("n", rhs, lhs, bufopts)
end

local function enable_codelens(bufnr)
  local java_cmds = vim.api.nvim_create_augroup('java_cmds', {clear = true})

  pcall(vim.lsp.codelens.refresh)

  vim.api.nvim_create_autocmd('BufWritePost', {
    buffer = bufnr,
    group = java_cmds,
    desc = 'refresh codelens',
    callback = function()
      pcall(vim.lsp.codelens.refresh)
    end,
  })
end

local function enable_debugger(bufnr)
  local bufopts = { noremap=true, silent=true, buffer=bufnr }

  require('jdtls').setup_dap({ hotcodereplace = 'auto' })

  nnoremap("<leader>vc", jdtls.test_class, bufopts, "Test class (DAP)")
  nnoremap("<leader>vm", jdtls.test_nearest_method, bufopts, "Test method (DAP)")
end

local on_attach = function(_, bufnr)
  enable_debugger(bufnr)
  enable_codelens(bufnr)

  jdtls.extendedClientCapabilities.resolveAdditionalTextEditsSupport = true

  nnoremap(
    "<leader><Enter>",
    '<cmd>:lua vim.lsp.buf.type_definition()<CR>',
    {},
    "Type definition"
  )
  nnoremap("<leader>ca", '<cmd>:lua vim.lsp.buf.code_action()<CR>', {}, "Code action")
  nnoremap("gd", '<cmd>:lua vim.lsp.buf.definition()<CR>', {}, "Definition")
  nnoremap("gr", require("telescope.builtin").lsp_references, {}, "Lsp references (telescope)")
  require('jdtls').setup_dap({ hotcodereplace = 'auto' })
end

local debugger_location = vim.fn.stdpath('data') .. '/mason/share'
local bundles = {
  vim.fn.glob(debugger_location .. "/java-debug-adapter/com.microsoft.java.debug.plugin-*.jar")
}

vim.list_extend(
  bundles,
  vim.split(vim.fn.glob(debugger_location .. '/java-test/*.jar'), '\n')
)

local config = {
  flags = {
    debounce_text_changes = 80,
  },
  init_options = {
    bundles = bundles
  },
  on_attach = on_attach,
  capabilities = require("cmp_nvim_lsp").default_capabilities(),
  root_dir = root_dir,
  settings = {
    java = {
      signatureHelp = { enabled = true },
      contentProvider = { preferred = 'fernflower' },
      completion = {
        favoriteStaticMembers = {
          "org.hamcrest.MatcherAssert.assertThat",
          "org.hamcrest.Matchers.*",
          "org.hamcrest.CoreMatchers.*",
          "org.junit.jupiter.api.Assertions.*",
          "java.util.Objects.requireNonNull",
          "java.util.Objects.requireNonNullElse",
          "org.mockito.Mockito.*"
        },
        filteredTypes = {
          "com.sun.*",
          "io.micrometer.shaded.*",
          "java.awt.*",
          "jdk.*", "sun.*",
        },
      },
      sources = {
        organizeImports = {
          starThreshold = 9999;
          staticStarThreshold = 9999;
        },
      },
      codeGeneration = {
        toString = {
          template = "${object.className}{${member.name()}=${member.value}, ${otherMembers}}"
        },
        hashCodeEquals = {
          useJava7Objects = true,
        },
        useBlocks = true,
      },
      configuration = {
        runtimes = {
          {
            name = "JavaSE-22",
            path = "/usr/lib/jvm/java-22-openjdk",
            default = true
          },
        }
      }
    }
  },

  cmd = {
    home .. '/.local/share/nvim/mason/bin/jdtls',
    '-Declipse.application=org.eclipse.jdt.ls.core.id1',
    '-Dosgi.bundles.defaultStartLevel=4',
    '-Declipse.product=org.eclipse.jdt.ls.core.product',
    '-Dlog.protocol=true',
    '-Dlog.level=ALL',
    '-Xmx256m',
    '-Xms100m',
    '-noverify',
    '-XX:+UseParallelGC',
    '-XX:GCTimeRatio=4',
    '-XX:AdaptiveSizePolicyWeight=90',
    '-Dsun.zip.disableMemoryMapping=true',
    '--jvm-arg=-javaagent:' .. path_to_lombok,
    '-jar ', path_to_jar,
    '-configuration ', home .. '/.local/share/nvim/mason/packages/jdtls/config_linux',
    '-data', workspace_folder,
    '--add-modules=ALL-SYSTEM',
    '--add-opens java.base/java.util=ALL-UNNAMED',
    '--add-opens java.base/java.lang=ALL-UNNAMED'
  },
}

jdtls.start_or_attach(config)
