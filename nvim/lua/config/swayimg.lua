-- Images open in one swayimg window beside the editor instead of as text:
-- foot can't draw images, and herdr only passes kitty graphics through. The
-- first image starts the window (appid swayimg-nvim) and later ones reuse it.
-- Its half of the handoff is in ~/.config/swayimg/init.lua; hyprland.lua
-- places the window and gives it SUPER+I.
local M = {}

M.extensions = { "png", "jpg", "jpeg", "gif", "webp", "bmp", "tif", "tiff", "svg", "avif", "heic", "jxl", "exr" }

local request = (vim.env.XDG_RUNTIME_DIR or "/tmp") .. "/swayimg-nvim"
local starting -- job id of a window this nvim started that isn't up yet

function M.is_image(path)
  return vim.tbl_contains(M.extensions, vim.fn.fnamemodify(path, ":e"):lower())
end

-- pid of the running window, once it's up and handling SIGUSR1
local function viewer_pid()
  local ok, lines = pcall(vim.fn.readfile, request .. ".pid")
  local pid = ok and tonumber(lines[1])
  local cmdline = pid and io.open("/proc/" .. pid .. "/cmdline")
  if not cmdline then
    return nil
  end
  local alive = cmdline:read("a"):find("--appid=swayimg-nvim", 1, true)
  cmdline:close()
  return alive and pid
end

function M.open(path)
  path = vim.fn.fnamemodify(path, ":p")
  vim.fn.writefile({ path }, request)
  local pid = viewer_pid()
  if pid then
    vim.uv.kill(pid, "sigusr1")
    -- a hidden window (or one on another workspace) comes back here
    vim.system({ "hyprctl", "dispatch", "swayimg_nvim.reveal" })
  elseif not (starting and vim.fn.jobwait({ starting }, 0)[1] == -1) then
    -- (a window still starting up reads the request once it's up)
    starting = vim.fn.jobstart({ "swayimg", "--appid=swayimg-nvim", path }, { detach = true })
  end
end

-- Reading an image into a buffer (:e, gf, pickers, neo-tree's P preview)
-- shows it in the window and leaves a stub listing the window's keys (the
-- cheatsheet's Images section) that can't be written back over the file.
function M.setup()
  local patterns = {}
  for _, ext in ipairs(M.extensions) do
    vim.list_extend(patterns, { "*." .. ext, "*." .. ext:upper() })
  end
  vim.api.nvim_create_autocmd("BufReadCmd", {
    group = vim.api.nvim_create_augroup("swayimg", { clear = true }),
    pattern = patterns,
    callback = function(ev)
      M.open(ev.match)
      local header = { " " .. vim.fn.fnamemodify(ev.match, ":~") .. " is shown in the swayimg window", "" }
      require("config.cheatsheet").draw_section(ev.buf, "Images", header)
      vim.bo[ev.buf].buftype = "nofile"
      vim.bo[ev.buf].bufhidden = "wipe"
      vim.bo[ev.buf].modifiable = false
    end,
  })
end

return M
