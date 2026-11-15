-- The markdown preview window (plugins/markdown.lua) opens on every machine
-- that is looking at this nvim: the one it runs on, and each machine attached
-- through a herdr remote client (ssh). Hyprland on each of them owns the
-- window (omarchy/.config/hypr/hyprland.lua, markdown_preview.*); a remote one
-- reaches the preview server through an ssh tunnel it opens back to this host.
local M = {}

-- { port, bufnr } of this nvim's preview server, once the plugin has started it
local page

local function process_environment(pid, name)
  local file = io.open("/proc/" .. pid .. "/environ", "r")
  if not file then
    return nil
  end
  local environ = file:read("*a")
  file:close()
  return environ:match("%z?" .. name .. "=(%Z*)")
end

local function tailnet_names_by_address()
  local names = {}
  local status = vim.system({ "tailscale", "status" }, { text = true }):wait()
  for address, name in (status.stdout or ""):gmatch("(%d+%.%d+%.%d+%.%d+)%s+(%S+)") do
    names[address] = name
  end
  return names
end

-- ssh targets of the machines attached through `herdr --remote`: each has a
-- remote-client-bridge here whose SSH_CONNECTION starts with its address.
-- NOTE: ssh to a bare tailnet address hangs from pml-w1, the name connects.
local function remote_viewers()
  local pids = vim.system({ "pgrep", "-f", "herdr remote-client-bridge" }, { text = true }):wait().stdout or ""
  local names = tailnet_names_by_address()
  local viewers = {}
  for pid in pids:gmatch("%d+") do
    local address = (process_environment(pid, "SSH_CONNECTION") or ""):match("^%S+")
    if address then
      viewers[names[address] or address] = true
    end
  end
  return vim.tbl_keys(viewers)
end

local function hyprland_everywhere(lua_local, lua_remote)
  vim.system({ "hyprctl", "eval", lua_local })
  for _, viewer in ipairs(remote_viewers()) do
    local command = "hyprctl -i 0 eval " .. vim.fn.shellescape(lua_remote)
    vim.system({ "ssh", "-o", "BatchMode=yes", "-o", "ConnectTimeout=5", viewer, command })
  end
end

local function open_everywhere()
  local arguments = ("%d, %d, %d"):format(page.port, page.bufnr, vim.fn.getpid())
  hyprland_everywhere(
    ('markdown_preview.open("", %s)'):format(arguments),
    ('markdown_preview.open("%s", %s)'):format(vim.uv.os_gethostname(), arguments)
  )
end

-- markdown-preview.nvim calls this (g:mkdp_browserfunc) with the page url when
-- its server first has something to show
function M.open(url)
  local port, bufnr = url:match(":(%d+)/page/(%d+)")
  page = { port = tonumber(port), bufnr = tonumber(bufnr) }
  open_everywhere()
end

-- <leader>cp: start the preview if needed, open it on a machine that attached
-- since, and bring it up over the editor everywhere
function M.show()
  vim.cmd("MarkdownPreview")
  if page then
    open_everywhere()
  end
  hyprland_everywhere("markdown_preview.show()", "markdown_preview.show()")
end

return M
