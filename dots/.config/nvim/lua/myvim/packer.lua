vim.cmd.packadd('packer.nvim')
local ensure_packer = function()
    local fn = vim.fn
    local install_path = fn.stdpath('data')..'/site/pack/packer/start/packer.nvim'
    if fn.empty(fn.glob(install_path)) > 0 then
        fn.system({'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path})
        vim.cmd [[packadd packer.nvim]]
        return true
    end
    return false
end

local packer_bootstrap = ensure_packer()

return require('packer').startup(function(use)

    use 'lewis6991/gitsigns.nvim'
    use 'romgrk/barbar.nvim'
    -- install without yarn or npm
    use({
        "iamcco/markdown-preview.nvim",
        run = function() vim.fn["mkdp#util#install"]() end,
    })

    use({ "iamcco/markdown-preview.nvim", run = "cd app && npm install", setup = function() vim.g.mkdp_filetypes = { "markdown" } end, ft = { "markdown" }, })

    use 'wbthomason/packer.nvim'
    use 'nvim-tree/nvim-web-devicons'
    use { "folke/which-key.nvim" }
    use 'roxma/vim-tmux-clipboard'
    use { "christoomey/vim-tmux-navigator" }
    use {
        'nvim-telescope/telescope.nvim',
        requires = { { 'nvim-lua/plenary.nvim' } }
    }
    use { "ellisonleao/gruvbox.nvim" }

    use({
        "folke/trouble.nvim",
        config = function()
            require("trouble").setup {
                icons=true
            }
        end
    })

    use({ 'nvim-treesitter/nvim-treesitter', })
    use ("tpope/vim-surround")
    use ("tpope/vim-commentary")
    use ("tpope/vim-fugitive")

    use ("theprimeagen/harpoon")
    use { "williamboman/mason.nvim"}
    use { "williamboman/mason-lspconfig.nvim", }

    use { "simrat39/rust-tools.nvim" }
    use { "neovim/nvim-lspconfig" }
    use('jose-elias-alvarez/null-ls.nvim')

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
                    ['<C-e>'] = cmp.mapping.abort(),
                    ['<CR>'] = cmp.mapping.confirm({
                        behavior = cmp.ConfirmBehavior.Replace,
                        select = false,
                    }),
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
    if packer_bootstrap then
        require('packer').sync()
    end

end)

