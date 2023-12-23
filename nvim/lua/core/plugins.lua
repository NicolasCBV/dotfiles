local ensure_packer = function()
  local fn = vim.fn
  local install_path = fn.stdpath("data").."/site/pack/packer/start/packer.nvim"
  if fn.empty(fn.glob(install_path)) > 0 then
    fn.system({"git", "clone", "--depth", "1", "https://github.com/wbthomason/packer.nvim", install_path})
    vim.cmd [[packadd packer.nvim]]
    return true
  end
  return false
end

local packer_bootstrap = ensure_packer()

require("packer").startup(function(use)
    -- ui lib
    use "MunifTanjim/nui.nvim"

    -- markdown preview
    use({
        "iamcco/markdown-preview.nvim",
        run = function() vim.fn["mkdp#util#install"]() end,
    })

	-- packer
    use "wbthomason/packer.nvim"

    -- Folding feature
    use {'kevinhwang91/nvim-ufo', requires = 'kevinhwang91/promise-async'}

    -- Debugger
    use {
      'mfussenegger/nvim-dap',
      requires = {
        'rcarriga/nvim-dap-ui',
        'mxsdev/nvim-dap-vscode-js'
      }
    }

    -- auto pairs 
    use "windwp/nvim-autopairs"

    -- Symbols
    use "simrat39/symbols-outline.nvim"

    -- devicons
	use "nvim-tree/nvim-web-devicons"

    -- bar
	use "romgrk/barbar.nvim"

    -- color scheme
	use "sainnhe/gruvbox-material"
	use "ellisonleao/gruvbox.nvim"

    -- language pack
	use "sheerun/vim-polyglot"

    -- lsp, completions & formatting
    use 'mfussenegger/nvim-jdtls'
    use {
      "hrsh7th/nvim-cmp",
      requires = {
        "hrsh7th/cmp-nvim-lsp",
        "L3MON4D3/LuaSnip",
        "saadparwaiz1/cmp_luasnip"
      }
    }

    use {
       "williamboman/mason.nvim",
       "williamboman/mason-lspconfig.nvim",
       "neovim/nvim-lspconfig"
    }

    -- tree sitter
    use("nvim-treesitter/nvim-treesitter", {run = ":TSUpdate"})

    -- file manager
    use {
      "nvim-neo-tree/neo-tree.nvim",
      branch = "v2.x",
      requires = {
        "nvim-lua/plenary.nvim",
        "nvim-tree/nvim-web-devicons",
        "MunifTanjim/nui.nvim",
      }
    }
    use {
      "nvim-telescope/telescope.nvim",
      requires = "nvim-lua/plenary.nvim",
    }

    -- terminal support
    use {
      "akinsho/toggleterm.nvim",
      tag = "*"
    }

    -- comment tool
    use "terrortylor/nvim-comment"

    -- lua line
    use {
      "nvim-lualine/lualine.nvim",
      requires = { 'nvim-tree/nvim-web-devicons', opt = true }
    }

    if packer_bootstrap then
      require("packer").sync()
    end
end)

