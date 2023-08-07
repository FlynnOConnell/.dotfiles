vim.cmd.packadd('packer.nvim')

return require('packer').startup(function(use)

    use 'wbthomason/packer.nvim'
    use 'nvim-tree/nvim-web-devicons'
    use { "folke/which-key.nvim" }
    use 'roxma/vim-tmux-clipboard'
    use { "christoomey/vim-tmux-navigator" }
    use { "catppuccin/nvim", as = "catppuccin",
    config=function() require("catppuccin").setup({
        flavor = "mocha",
        background = {dark="mocha"},
        integrations = {
            cmp = true,
            telescope = true,
        }
    }) end }

    use {
        'nvim-lualine/lualine.nvim',
        requires = { 'nvim-tree/nvim-web-devicons', opt = true },
        config = function()
            require('lualine').setup({
                options = { theme = "auto" },
                sections = {
                    lualine_a = {
                        {
                            'filename',
                            file_status = false,
                            newfile_status = false,
                            path = 4,
                            shorting_target = 40,
                            symbols = {
                                modified = '[+]',
                                readonly = '[-]',
                                unnamed = '[No Name]',
                                newfile = '[New]',
                            }
                        }
                    }
                }
            })
        end
    }

    use {
        'nvim-telescope/telescope.nvim', tag = '0.1.1',
        requires = { { 'nvim-lua/plenary.nvim' } }
    }

    use({
        "folke/trouble.nvim",
        config = function()
            require("trouble").setup {
                icons=true
            }
        end
    })

    use({
        'nvim-treesitter/nvim-treesitter',
        run = function()
            local ts_update = require('nvim-treesitter.install').update({ with_sync = true })
            ts_update()
        end,
    })
    use {
        'saecki/crates.nvim',
        tag = 'v0.3.0',
        requires = { 'nvim-lua/plenary.nvim' },
        config = function()
            require('crates').setup()
        end,
    }
    use ("tpope/vim-vinegar")
    use ("tpope/vim-surround")
    use ("tpope/vim-commentary")
    use ("tpope/vim-fugitive")

    use("theprimeagen/harpoon")
    use("mbbill/undotree")

    use { "williamboman/mason.nvim"}
    use {
        "williamboman/mason-lspconfig.nvim",
        config = function()
            require("mason-lspconfig").setup({
                ensure_installed = {
                    "bashls",
                    "cssls",
                    "eslint",
                    "html",
                    "jsonls",
                    "lua_ls",
                    "rust_analyzer",
                    "tsserver",
                    'dockerls',
                    'docker_compose_language_service',
                    'dotls',
                },
            })
        end,
    }

    use { "simrat39/rust-tools.nvim" }
    use { "neovim/nvim-lspconfig" }

    use {
        'hrsh7th/nvim-cmp',
        requires = {
            'hrsh7th/cmp-buffer',
            'hrsh7th/cmp-nvim-lsp',
            'saadparwaiz1/cmp_luasnip',
            'hrsh7th/cmp-nvim-lua',
            'L3MON4D3/LuaSnip',
            'rafamadriz/friendly-snippets'
        },
        config = function()
            local cmp = require('cmp')
            cmp.setup({
                snippet = {
                    expand = function(args)
                        require('luasnip').lsp_expand(args.body)
                    end,
                },
                mapping = {
                    ['<C-j>'] = cmp.mapping.select_prev_item(),
                    ['<C-k>'] = cmp.mapping.select_next_item(),
                    ['<C-y>'] = cmp.mapping.confirm({
                        behavior = cmp.ConfirmBehavior.Replace,
                        select = true,
                    }),
                    ['<C-Space>'] = cmp.mapping.complete(),
                },
                sources = {
                    { name = 'nvim_lsp' },
                    { name = 'buffer' },
                    { name = 'luasnip' },
                    { name = 'nvim_lua' },
                }
            })
        end
    }
    use("folke/zen-mode.nvim")
    use("github/copilot.vim")
end)

