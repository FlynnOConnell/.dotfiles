vim.cmd.packadd('packer.nvim')

return require('packer').startup(function(use)

    use {
        'rust-lang/rust.vim',
        event = 'FileType rust',
        config = function()
            vim.g.rustfmt_autosave = 1
        end
    }

    use 'lewis6991/gitsigns.nvim'
    use 'romgrk/barbar.nvim'

    use 'wbthomason/packer.nvim'
    use 'nvim-tree/nvim-web-devicons'
    use { "folke/which-key.nvim" }
    use 'roxma/vim-tmux-clipboard'
    use { "christoomey/vim-tmux-navigator" }
    use { "catppuccin/nvim",
    as = "catppuccin",
    run = ":CatppuccinCompile"
}
use{
	    'norcalli/nvim-colorizer.lua',
	    config = function()
			require('colorizer').setup()
	    end
	}

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
        -- tag = 'v0.3.0',
        requires = { 'nvim-lua/plenary.nvim' },
        config = function()
            require('crates').setup()
            local crates = require('crates')
            local opts = { silent = true }

            vim.keymap.set('n', '<leader>cr', crates.reload, opts)

            vim.keymap.set('n', '<leader>cf', crates.show_features_popup, opts)
            vim.keymap.set('n', '<leader>cd', crates.show_dependencies_popup, opts)

            vim.keymap.set('n', '<leader>cu', crates.update_crate, opts)
            vim.keymap.set('v', '<leader>cu', crates.update_crates, opts)
            vim.keymap.set('n', '<leader>ca', crates.update_all_crates, opts)
        end,
    }
    use {
        "nvim-neo-tree/neo-tree.nvim",
        branch = "v3.x",
        requires = {
            "nvim-lua/plenary.nvim",
            "nvim-tree/nvim-web-devicons",
            "MunifTanjim/nui.nvim",
            {
                -- only needed if you want to use the commands with "_with_window_picker" suffix
                's1n7ax/nvim-window-picker',
                tag = "v1.*",
                config = function()
                    require'window-picker'.setup({
                        autoselect_one = true,
                        include_current = false,
                        filter_rules = {
                            bo = {
                                -- if the file type is one of following, the window will be ignored
                                filetype = { 'neo-tree', "neo-tree-popup", "notify" },

                                -- if the buffer type is one of following, the window will be ignored
                                buftype = { 'terminal', "quickfix" },
                            },
                        },
                    })
                end,
            }
        },
        config = function ()
            require("neo-tree").setup({
                close_if_last_window = true, -- Close Neo-tree if it is the last window left in the tab
                popup_border_style = "rounded",
                enable_git_status = true,
                enable_diagnostics = false,
                enable_normal_mode_for_inputs = false, -- Enable normal mode for input dialogs.
                open_files_do_not_replace_types = { "terminal", "trouble", "qf" }, -- when opening files, do not use windows containing these filetypes or buftypes
                sort_case_insensitive = false, -- used when sorting files and directories in the tree
                sort_function = nil ,
                default_component_configs = {
                    container = {
                        enable_character_fade = true
                    },
                    indent = {
                        indent_size = 1,
                        padding = 0, -- extra padding on left hand side
                        -- indent guides
                        with_markers = true,
                        indent_marker = "│",
                        last_indent_marker = "└",
                        highlight = "NeoTreeIndentMarker",
                        -- expander config, needed for nesting files
                        with_expanders = nil, -- if nil and file nesting is enabled, will enable expanders
                        expander_collapsed = "",
                        expander_expanded = "",
                        expander_highlight = "NeoTreeExpander",
                    },
                    icon = {
                        folder_closed = "",
                        folder_open = "",
                        folder_empty = "󰜌",
                    },
                    name = {
                        trailing_slash = false,
                        use_git_status_colors = true,
                        highlight = "NeoTreeFileName",
                    },
                },
                -- A list of functions, each representing a global custom command
                -- that will be available in all sources (if not overridden in `opts[source_name].commands`)
                -- see `:h neo-tree-custom-commands-global`
                commands = {},
                window = {
                    position = "left",
                    width = 35,
                    mapping_options = {
                        noremap = true,
                        nowait = true,
                    },
                    mappings = {
                        ["<space>"] = {
                            "toggle_node",
                        },
                        ["<2-LeftMouse>"] = "open",
                        ["<cr>"] = "open",
                        ["<esc>"] = "cancel",
                        ["P"] = { "toggle_preview", config = { use_float = true } },
                        ["l"] = "focus_preview",
                        ["S"] = "open_split",
                        ["s"] = "open_vsplit",
                        -- ["S"] = "split_with_window_picker",
                        -- ["s"] = "vsplit_with_window_picker",
                        ["t"] = "open_tabnew",
                        -- ["<cr>"] = "open_drop",
                        -- ["t"] = "open_tab_drop",
                        ["w"] = "open_with_window_picker",
                        --["P"] = "toggle_preview", -- enter preview mode, which shows the current node without focusing
                        ["C"] = "close_node",
                        -- ['C'] = 'close_all_subnodes',
                        ["z"] = "close_all_nodes",
                        ["Z"] = "expand_all_nodes",
                        ["a"] = {
                            "add",
                            -- this command supports BASH style brace expansion ("x{a,b,c}" -> xa,xb,xc). see `:h neo-tree-file-actions` for details
                            -- some commands may take optional config options, see `:h neo-tree-mappings` for details
                            config = {
                                show_path = "none" -- "none", "relative", "absolute"
                            }
                        },
                        ["A"] = "add_directory", -- also accepts the optional config.show_path option like "add". this also supports BASH style brace expansion.
                        ["d"] = "delete",
                        ["r"] = "rename",
                        ["y"] = "copy_to_clipboard",
                        ["x"] = "cut_to_clipboard",
                        ["p"] = "paste_from_clipboard",
                        ["c"] = "copy", -- takes text input for destination, also accepts the optional config.show_path option like "add":
                        -- ["c"] = {
                            --  "copy",
                            --  config = {
                                --    show_path = "none" -- "none", "relative", "absolute"
                                --  }
                                --}
                                ["m"] = "move", -- takes text input for destination, also accepts the optional config.show_path option like "add".
                                ["q"] = "close_window",
                                ["R"] = "refresh",
                                ["?"] = "show_help",
                                ["<"] = "prev_source",
                                [">"] = "next_source",
                            }
                        },
                        nesting_rules = {},
                        filesystem = {
                            filtered_items = {
                                visible = false, -- when true, they will just be displayed differently than normal items
                                hide_dotfiles = false,
                                hide_hidden = false,
                                hide_by_name = {
                                    --"node_modules"
                                },
                                hide_by_pattern = { -- uses glob style patterns
                                --"*.meta",
                                --"*/src/*/tsconfig.json",
                            },
                            always_show = {
                                ".gitignore",
                                "*.json",
                            },
                            never_show = { -- remains hidden even if visible is toggled to true, this overrides always_show
                            ".DS_Store",
                            "thumbs.db"
                        },
                        never_show_by_pattern = { -- uses glob style patterns
                        --".null-ls_*",
                    },
                },
                follow_current_file = {
                    enabled = true, -- This will find and focus the file in the active buffer every time
                    --               -- the current file is changed while the tree is open.
                    leave_dirs_open = false, -- `false` closes auto expanded dirs, such as with `:Neotree reveal`
                },
                group_empty_dirs = false, -- when true, empty folders will be grouped together
                hijack_netrw_behavior = "open_default", -- netrw disabled, opening a directory opens neo-tree
                -- in whatever position is specified in window.position
                -- "open_current",  -- netrw disabled, opening a directory opens within the
                -- window like netrw would, regardless of window.position
                -- "disabled",    -- netrw left alone, neo-tree does not handle opening dirs
                use_libuv_file_watcher = false, -- This will use the OS level file watchers to detect changes
                -- instead of relying on nvim autocmd events.
                window = {
                    mappings = {
                        ["<bs>"] = "navigate_up",
                        ["."] = "set_root",
                        ["H"] = "toggle_hidden",
                        ["/"] = "fuzzy_finder",
                        ["D"] = "fuzzy_finder_directory",
                        ["#"] = "fuzzy_sorter",
                        -- ["D"] = "fuzzy_sorter_directory",
                        ["f"] = "filter_on_submit",
                        ["<c-x>"] = "clear_filter",
                        ["[g"] = "prev_git_modified",
                        ["]g"] = "next_git_modified",
                    },
                    fuzzy_finder_mappings = { -- define keymaps for filter popup window in fuzzy_finder_mode
                    ["<down>"] = "move_cursor_down",
                    ["<C-n>"] = "move_cursor_down",
                    ["<up>"] = "move_cursor_up",
                    ["<C-p>"] = "move_cursor_up",
                },
            },
        },
        buffers = {
            follow_current_file = {
                enabled = true, -- This will find and focus the file in the active buffer every time
                --              -- the current file is changed while the tree is open.
                leave_dirs_open = false, -- `false` closes auto expanded dirs, such as with `:Neotree reveal`
            },
            group_empty_dirs = true, -- when true, empty folders will be grouped together
            show_unloaded = true,
            window = {
                mappings = {
                    ["bd"] = "buffer_delete",
                    ["<bs>"] = "navigate_up",
                    ["."] = "set_root",
                }
            },
        },
        git_status = {
            window = {
                position = "float",
                mappings = {
                    ["A"]  = "git_add_all",
                    ["gu"] = "git_unstage_file",
                    ["ga"] = "git_add_file",
                    ["gr"] = "git_revert_file",
                    ["gc"] = "git_commit",
                    ["gp"] = "git_push",
                    ["gg"] = "git_commit_and_push",
                }
            }
        }
    })
    vim.cmd([[nnoremap \ :Neotree reveal<cr>]])
end
}
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
use('jose-elias-alvarez/null-ls.nvim')
use('MunifTanjim/prettier.nvim')

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

end)

