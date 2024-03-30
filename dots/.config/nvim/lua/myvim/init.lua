require("myvim.set")
require("myvim.remap")
require("mason").setup()
require("mason-lspconfig").setup()

vim.api.nvim_set_keymap('n', '<Leader>cf', ':lua vim.lsp.buf.formatting()<CR>', { noremap = true, silent = true })

local augroup = vim.api.nvim_create_augroup
local MyVimGroup = augroup('MyVim', {})

local autocmd = vim.api.nvim_create_autocmd
local yank_group = augroup('HighlightYank', {})

function R(name)
    require("plenary.reload").reload_module(name)
end

-- shorten (40s) duration of highlighted yank
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

-- trimming trailing whitespace
autocmd({"BufWritePre"}, {
    group = MyVimGroup,
    pattern = "*",
    command = [[%s/\s\+$//e]],
})


local system_name
if os.getenv("OS") == "Windows_NT" then
    system_name = "Windows"
else
    -- Unix-like system, check for specific distributions
    local handle = io.popen("uname -s")
    system_name = handle:read("*l")
    handle:close()
end


-- Close unused buffers
local id = vim.api.nvim_create_augroup("startup", {
  clear = false
})

local persistbuffer = function(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  vim.fn.setbufvar(bufnr, 'bufpersist', 1)
end

vim.api.nvim_create_autocmd({"BufRead"}, {
  group = id,
  pattern = {"*"},
  callback = function()
    vim.api.nvim_create_autocmd({"InsertEnter","BufModifiedSet"}, {
      buffer = 0,
      once = true,
      callback = function()
        persistbuffer()
      end
    })
  end
})

vim.keymap.set('n', '<Leader>b',
  function()
    local curbufnr = vim.api.nvim_get_current_buf()
    local buflist = vim.api.nvim_list_bufs()
    for _, bufnr in ipairs(buflist) do
      if vim.bo[bufnr].buflisted and bufnr ~= curbufnr and (vim.fn.getbufvar(bufnr, 'bufpersist') ~= 1) then
        vim.cmd('bd ' .. tostring(bufnr))
      end
    end
  end, { silent = true, desc = 'Close unused buffers' })
