require("flynnvim.set")
require("flynnvim.remap")
require("flynnvim.maps")
require("mason").setup()
require("mason-lspconfig").setup()

local augroup = vim.api.nvim_create_augroup
local FlynnVimGroup = augroup('FlynnVim', {})

local autocmd = vim.api.nvim_create_autocmd
local yank_group = augroup('HighlightYank', {})

function R(name)
    require("plenary.reload").reload_module(name)
end

autocmd('TextYankPost', {
    group = yank_group,
    pattern = '*',
    callback = function()
        vim.highlight.on_yank({
            higroup = 'IncSearch',
            timeout = 40,
        })
    end,
})

autocmd({"BufWritePre"}, {
    group = FlynnVimGroup,
    pattern = "*",
    command = [[%s/\s\+$//e]],
})

vim.g.netrw_browse_split = 0
vim.g.netrw_banner = 0
vim.g.netrw_winsize = 25
vim.cmd.colorscheme "catppuccin"

local system_name
if os.getenv("OS") == "Windows_NT" then
    system_name = "Windows"
else
    -- Unix-like system, check for specific distributions
    local handle = io.popen("uname -s")
    system_name = handle:read("*l")
    handle:close()
end

if system_name == "Windows" then
    vim.g.clipboard = {
        name = 'WslClipboard',
        copy = {
            ['+'] = '/mnt/c/Windows/System32/clip.exe',
            ['*'] = '/mnt/c/Windows/System32/clip.exe',
        },
        paste = {
            ['+'] = '/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))',
            ['*'] = '/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))',
        },
        cache_enabled = 0,
    }
elseif system_name == "Darwin" then
    -- Configurations for MacOS
    vim.g.clipboard = {
        name = 'macOS-clipboard',
        copy = {
            ['+'] = 'pbcopy',
            ['*'] = 'pbcopy',
        },
        paste = {
            ['+'] = 'pbpaste',
            ['*'] = 'pbpaste',
        },
        cache_enabled = 0,
    }
end
