require("myvim")

-- Custom function to check for single empty buffer
function close_if_single_empty_buffer()
  local empty_buffer = true
  local buf_list = vim.api.nvim_list_bufs()
  local buf_count = 0

  for _, buf in ipairs(buf_list) do
    if vim.api.nvim_buf_line_count(buf) > 1 then
      empty_buffer = false
      break
    end
    buf_count = buf_count + 1
  end

  if empty_buffer and buf_count == 1 then
    vim.cmd('quit')
  else
    vim.cmd('wq')
  end
end

-- Map :x, :q, :wq to the custom function
vim.api.nvim_set_keymap('n', ':x', [[<Cmd>lua close_if_single_empty_buffer()<CR>]], { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', ':wq', [[<Cmd>lua close_if_single_empty_buffer()<CR>]], { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', ':q', [[<Cmd>lua close_if_single_empty_buffer()<CR>]], { noremap = true, silent = true })

