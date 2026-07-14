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

-- Check if clipboard has an image
local function clipboard_has_image()
  local handle = io.popen('xclip -selection clipboard -t TARGETS -o 2>/dev/null')
  if handle then
    local result = handle:read '*a'
    handle:close()
    return result:match 'image/png' or result:match 'image/jpeg' or result:match 'image/jpg'
  end
  return false
end

-- Paste image from clipboard to static/images
local function paste_clipboard_image()
  local images_dir = vault_path .. '/static/images'
  vim.fn.mkdir(images_dir, 'p')

  local timestamp = os.date '%Y-%m-%d-%H-%M-%S'
  local filename = timestamp .. '.png'
  local filepath = images_dir .. '/' .. filename

  local cmd = string.format('xclip -selection clipboard -t image/png -o > "%s"', filepath)
  local result = os.execute(cmd)

  if result == 0 or result == true then
    local link = string.format('![%s](static/images/%s)', timestamp, filename)
    vim.api.nvim_put({ link }, 'c', true, true)
    vim.notify('Image saved: ' .. filename)
    return true
  else
    vim.notify('Failed to save clipboard image', vim.log.levels.ERROR)
    return false
  end
end

-- Paste/link media file (image or video)
local function paste_media_file()
  vim.ui.input({ prompt = 'Media file path: ', completion = 'file' }, function(input)
    if not input or input == '' then return end

    local src = vim.fn.expand(input)
    if vim.fn.filereadable(src) ~= 1 then
      vim.notify('File not found: ' .. src, vim.log.levels.ERROR)
      return
    end

    local filename = vim.fn.fnamemodify(src, ':t')
    local ext = vim.fn.fnamemodify(src, ':e'):lower()

    -- Determine if image or video based on extension
    local image_exts = { png = true, jpg = true, jpeg = true, gif = true, webp = true, svg = true }
    local is_image = image_exts[ext] or false

    local dest_dir = is_image and (vault_path .. '/static/images') or (vault_path .. '/static/videos')
    local rel_path = is_image and 'static/images' or 'static/videos'

    vim.fn.mkdir(dest_dir, 'p')
    local dest = dest_dir .. '/' .. filename

    -- Copy file
    local ok = vim.fn.writefile(vim.fn.readblob(src), dest, 'b')
    if ok ~= 0 then
      vim.notify('Failed to copy file', vim.log.levels.ERROR)
      return
    end

    -- Insert markdown link
    local link = string.format('![%s](%s/%s)', filename:gsub('%.[^.]+$', ''), rel_path, filename)
    vim.api.nvim_put({ link }, 'c', true, true)
    vim.notify((is_image and 'Image' or 'Video') .. ' linked: ' .. filename)
  end)
end

-- Unified paste: clipboard image first, then prompt for file
_G.paste_media = function()
  if clipboard_has_image() then
    paste_clipboard_image()
  else
    paste_media_file()
  end
end

-- Legacy alias
_G.paste_video = _G.paste_media

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
      { '<leader>V', '<cmd>lua paste_media()<cr>', desc = 'Paste [V]ideo/image (clipboard or file)' },
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
