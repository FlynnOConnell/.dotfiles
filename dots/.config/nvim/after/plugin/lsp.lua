local nvim_lsp = require('lspconfig')
local servers = {
    "bashls",
    "pyright",
    "jsonls",
    "lua_ls",
    "rust_analyzer",
}

local on_attach = function(_, bufnr)
    local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end
    local function buf_set_option(...) vim.api.nvim_buf_set_option(bufnr, ...) end

    -- Enable completion triggered by <c-x><c-o>
    buf_set_option('omnifunc', 'v:lua.vim.lsp.omnifunc')

    -- Mappings.
    local opts = { noremap=true, silent=true }
    -- See `:help vim.lsp.*` for documentation on any of the below functions
    buf_set_keymap('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<CR>', opts)
    buf_set_keymap('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>', opts)
    buf_set_keymap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
    buf_set_keymap('n', 'gr', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
    buf_set_keymap('n', 'gh', '<cmd>lua vim.lsp.buf.code_action()<CR>', {noremap=true, silent=false})

    buf_set_keymap('n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>', opts)

    buf_set_keymap('n', '<leader>wa', '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>', opts)
    buf_set_keymap('n', '<leader>wr', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>', opts)
    buf_set_keymap('n', '<leader>wl', '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>', opts)
end

local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require('cmp_nvim_lsp').default_capabilities()

require('rust-tools').setup({
    server = {
        on_attach = on_attach,
        capabilities = capabilities,
        settings = {
            ["rust-analyzer"] = {
                checkOnSave = {
                    command = "clippy"
                }
            }
        }
    }
})

for _, server in ipairs(servers) do
    nvim_lsp[server].setup {
        on_attach = on_attach,
        capabilities = capabilities,
        autostart = true,
        settings = {
            Lua = {
                diagnostics = { globals = {'vim'} }
            },
            pylsp = {
                plugins = {

                    maxLineLength = 250,
                    jedi_completion = {
                        include_class_objects = true,
                        include_function_objects = true
                    },
                    jedi = { environment = os.getenv("VENV_PATH_PYLSP") }
                },

            },
        },
        handlers = {
            ["textDocument/publishDiagnostics"] = vim.lsp.with(
            vim.lsp.diagnostic.on_publish_diagnostics, {
                -- Disable virtual text
                virtual_text = false,
                -- Enable signs
                signs = true,
                -- Enable underline
                underline = true,
                -- Enable diagnostics pop-up on hover
                update_in_insert = false,
            }
            ),
        },
    }
end
local wk = require("which-key")

wk.setup {}

wk.register({
    ["<leader>"] = {
        g = {
            name = "+LSP",
            D = "Go to Declaration",
            d = "Go to Definition",
            i = "Go to Implementation",
            r = "Rename",
        },
        ["w"] = {
            name = "+workspace",
            a = "Add Workspace Folder",
            r = "Remove Workspace Folder",
            l = "List Workspace Folders",
            D = "Go to Type Definition",
            q = "Set Diagnostic to Location List",
        },
    },
    ["<C-k>"] = "Show Signature Help",
    ["O"] = "Open Diagnostic Float",
    ["ce"] = "Show Line Diagnostics",
    gh = "Code Action",
    K = "Hover",
    f = "format document",
})
