-- Plugins tab (replaces the lazy.nvim popup for everyday use):  <Space>pl · activity bar · `:IDEPlugins`
-- Actions on top, every plugin with its load state, and the language tools Mason installed.
--   Enter/click run an action or open a plugin's repo · u update plugin · l load now · o open repo · r refresh · q close
-- The full lazy.nvim UI is still one key away (L) for advanced work.
local ui = require("config.ui")
local M = {}

local sections = { "Actions", "Plugins", "Language tools" }

local actions = {
  { label = "Update all plugins", desc = "Pull the latest version of every plugin (rewrites lazy-lock.json)", run = function() vim.cmd("Lazy! update") end },
  { label = "Sync", desc = "Install missing, remove unused, update everything", run = function() vim.cmd("Lazy! sync") end },
  { label = "Restore from lockfile", desc = "Go back to the versions pinned in lazy-lock.json", run = function() vim.cmd("Lazy! restore") end },
  { label = "Update language tools", desc = "Update servers, formatters and debuggers installed through Mason", run = function() pcall(vim.cmd, "MasonToolsUpdate") end },
  { label = "Install / remove language tools", desc = "Open Mason", run = function() vim.cmd("Mason") end },
  { label = "Startup profile", desc = "Which plugins cost startup time", run = function() vim.cmd("Lazy profile") end },
  { label = "Open the full lazy.nvim UI", desc = "Advanced view: logs, diffs, per-plugin tasks", run = function() vim.cmd("Lazy") end },
}

local function plugin_list()
  local ok, cfgm = pcall(require, "lazy.core.config")
  if not ok then return {} end
  local out = {}
  for name, p in pairs(cfgm.plugins) do
    local trigger = {}
    if p.event then trigger[#trigger + 1] = "event" end
    if p.cmd then trigger[#trigger + 1] = "cmd" end
    if p.keys then trigger[#trigger + 1] = "keys" end
    if p.ft then trigger[#trigger + 1] = "ft" end
    out[#out + 1] = { name = name, repo = p[1] or p.url or "", loaded = p._ and p._.loaded ~= nil, installed = p._ and p._.installed, lazy = p.lazy, trigger = table.concat(trigger, "+") }
  end
  table.sort(out, function(a, b) if a.loaded ~= b.loaded then return a.loaded end return a.name:lower() < b.name:lower() end)
  return out
end

local function mason_tools()
  local ok, reg = pcall(require, "mason-registry")
  if not ok then return {} end
  local names = reg.get_installed_package_names()
  table.sort(names)
  return names
end

local page = ui.page({
  name = "Plugins", ft = "ide-plugins", sections = sections,
  render = function(_, b)
    local plugins = plugin_list()
    local loaded = 0; for _, p in ipairs(plugins) do if p.loaded then loaded = loaded + 1 end end
    local ms = ""
    local okl, lazy = pcall(require, "lazy"); if okl then local s = lazy.stats(); ms = string.format(" \xc2\xb7 started in %.0f ms", s.startuptime or 0) end
    b:title("Plugins", string.format("lazy.nvim \xc2\xb7 %d plugins \xc2\xb7 %d loaded%s \xc2\xb7 Enter / click to run", #plugins, loaded, ms))
    b:jumpbar(sections)

    b:head(sections[1], 1)
    for _, a in ipairs(actions) do
      local first = #b.lines + 1
      b:add(b.margin .. "  " .. a.label, "IDEAccent", { action = a, first = first, last = first + 1 })
      b:add(b.margin .. "  " .. a.desc, "IDEMuted", { action = a, first = first, last = first + 1 })
      b:blank()
    end

    b:head(sections[2], 2)
    for _, p in ipairs(plugins) do
      local dot = p.loaded and ui.g("loaded") or ui.g("idle")
      local line = b.margin .. dot .. " " .. string.format("%-26s", p.name) .. string.format("%-34s", p.repo) .. (p.loaded and "loaded" or ("idle" .. (p.trigger ~= "" and (" \xc2\xb7 on " .. p.trigger) or "")))
      b:add(line, p.loaded and nil or "IDEMuted", { plugin = p, first = #b.lines + 1, last = #b.lines + 1 })
    end

    b:head(sections[3], 3)
    local tools = mason_tools()
    if #tools == 0 then b:add(b.margin .. "No tools installed yet. They install automatically for the languages you enable (Settings > Languages).", "IDEMuted") end
    local row = {}
    for i, t in ipairs(tools) do
      row[#row + 1] = string.format("%-28s", t)
      if #row == 3 or i == #tools then b:add(b.margin .. table.concat(row), nil, { tool = true }); row = {} end
    end
    b:blank()
    b:add(b.margin .. "Install or remove tools with the Mason action above.", "IDEMuted")
    b:blank()
  end,
  select = function(p, line)
    local m = p.meta[line]
    if m and (m.action or m.plugin) then return m.first, m.last end
  end,
  keys = {
    ["<CR>"] = function(p) M.activate(p, p.meta[p:line()]) end,
    ["<Space>"] = function(p) M.activate(p, p.meta[p:line()]) end,
    u = function(p) local m = p.meta[p:line()]; if m and m.plugin then vim.cmd("Lazy! update " .. m.plugin.name); M.refresh_later(p) end end,
    l = function(p) local m = p.meta[p:line()]; if m and m.plugin then pcall(vim.cmd, "Lazy! load " .. m.plugin.name); M.refresh_later(p) end end,
    o = function(p) local m = p.meta[p:line()]; if m and m.plugin and m.plugin.repo:find("/") then vim.ui.open("https://github.com/" .. m.plugin.repo) end end,
    r = function(p) p:render(); p:mark() end,
  },
  click = function(p, _, meta) if meta and meta.action then M.activate(p, meta) end end,
})

function M.refresh_later(p) vim.defer_fn(function() if p:valid() then p:render(); p:mark() end end, 1500) end

function M.activate(p, meta)
  if not meta then return end
  if meta.action then pcall(meta.action.run); M.refresh_later(p)
  elseif meta.plugin and meta.plugin.repo:find("/") then vim.ui.open("https://github.com/" .. meta.plugin.repo) end
end

function M.open() page:open() end

vim.api.nvim_create_user_command("IDEPlugins", M.open, { desc = "Open the Plugins tab" })
return M
