-- Markdown utilities: image paste, video link, and code block wrappers
local vault_path = vim.fn.expand '~/repos/docs'

-- toggle checkbox on current line: unchecked -> checked, checked -> unchecked
_G.toggle_checkbox = function()
  local line = vim.api.nvim_get_current_line()
  if line:match '%[x%]' or line:match '%[X%]' then
    line = line:gsub('%[[xX]%]', '[ ]', 1)
  elseif line:match '%[~%]' then
    line = line:gsub('%[~%]', '[x]', 1)
  elseif line:match '%[ %]' then
    line = line:gsub('%[ %]', '[x]', 1)
  elseif line:match '^%s*%-' then
    line = line:gsub('(%-) ', '%1 [ ] ', 1)
  else
    return
  end
  vim.api.nvim_set_current_line(line)
end

-- set current line checkbox to in-progress [~]
_G.toggle_partial = function()
  local line = vim.api.nvim_get_current_line()
  if line:match '%[~%]' then
    line = line:gsub('%[~%]', '[ ]', 1)
  elseif line:match '%[[xX ]%]' then
    line = line:gsub('%[[xX ]%]', '[~]', 1)
  elseif line:match '^%s*%-' then
    line = line:gsub('(%-) ', '%1 [~] ', 1)
  else
    return
  end
  vim.api.nvim_set_current_line(line)
end

-- Make wrap_python globally accessible
_G.wrap_python_codeblock = function()
  local start_line = vim.fn.line "'<"
  local end_line = vim.fn.line "'>"
  vim.api.nvim_buf_set_lines(0, end_line, end_line, false, { '```' })
  vim.api.nvim_buf_set_lines(0, start_line - 1, start_line - 1, false, { '```python' })
end

-- Paste/link video file
_G.paste_video = function()
  local video_dir = vault_path .. '/static/videos'
  vim.fn.mkdir(video_dir, 'p')

  vim.ui.input({ prompt = 'Video path: ', completion = 'file' }, function(input)
    if not input or input == '' then return end

    local src = vim.fn.expand(input)
    if vim.fn.filereadable(src) ~= 1 then
      vim.notify('File not found: ' .. src, vim.log.levels.ERROR)
      return
    end

    local filename = vim.fn.fnamemodify(src, ':t')
    local dest = video_dir .. '/' .. filename

    -- Copy file
    local ok = vim.fn.writefile(vim.fn.readblob(src), dest, 'b')
    if ok ~= 0 then
      vim.notify('Failed to copy video', vim.log.levels.ERROR)
      return
    end

    -- Insert markdown link
    local link = string.format('![%s](static/videos/%s)', filename:gsub('%.[^.]+$', ''), filename)
    vim.api.nvim_put({ link }, 'c', true, true)
    vim.notify('Video linked: ' .. filename)
  end)
end

return {
  {
    'HakonHarnes/img-clip.nvim',
    event = 'VeryLazy',
    opts = {
      default = {
        dir_path = function()
          return vault_path .. '/static/images'
        end,
        relative_to_current_file = false,
        file_name = '%Y-%m-%d-%H-%M-%S',
        extension = 'png',
        prompt_for_file_name = false,
        use_absolute_path = false,
        insert_mode_after_paste = false,
      },
    },
    keys = {
      { '<leader>P', '<cmd>PasteImage<cr>', desc = '[P]aste image from clipboard' },
      { '<leader>V', '<cmd>lua paste_video()<cr>', desc = 'Link [V]ideo file' },
      { '<leader>C', '<esc><cmd>lua wrap_python_codeblock()<cr>', desc = 'Wrap in python [C]ode block', mode = 'v' },
      { '<leader>tx', '<cmd>lua toggle_checkbox()<cr>', desc = '[T]oggle checkbox [x]', ft = 'markdown' },
      { '<leader>t~', '<cmd>lua toggle_partial()<cr>', desc = '[T]oggle in-progress [~]', ft = 'markdown' },
    },
  },
  {
    'iamcco/markdown-preview.nvim',
    cmd = { 'MarkdownPreviewToggle', 'MarkdownPreview', 'MarkdownPreviewStop' },
    ft = { 'markdown' },
    build = 'cd app && npm install',
    keys = {
      { '<leader>mp', '<cmd>MarkdownPreviewToggle<cr>', desc = '[M]arkdown [P]review toggle' },
    },
  },
}
