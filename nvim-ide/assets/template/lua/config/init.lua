-- Shared helpers: loads settings (+ saved overrides from the Settings page)
-- and resolves language presets into flat lists.
local M = {}

local base = require("config.settings")
M.defaults = vim.deepcopy(base)
M.override_path = vim.fn.stdpath("data") .. "/ide-settings.json"

function M.load_overrides()
  local f = io.open(M.override_path, "r")
  if not f then return {} end
  local txt = f:read("*a"); f:close()
  local ok, data = pcall(vim.json.decode, txt)
  return (ok and type(data) == "table") and data or {}
end

local function prune(t) -- drop empty tables so JSON never contains [] / {} noise
  for k, v in pairs(t) do
    if type(v) == "table" then
      if next(v) == nil then t[k] = nil elseif not vim.islist(v) then prune(v); if next(v) == nil then t[k] = nil end end
    end
  end
  return t
end

function M.save_overrides(tbl)
  tbl = prune(tbl)
  vim.fn.mkdir(vim.fn.fnamemodify(M.override_path, ":h"), "p")
  local f = assert(io.open(M.override_path, "w"))
  f:write(next(tbl) and vim.json.encode(tbl) or "{}"); f:close()
end

local overrides = M.load_overrides()
M.settings = vim.tbl_deep_extend("force", base, overrides)
-- lists are replaced wholesale, never merged
if overrides.languages then M.settings.languages = overrides.languages end

local presets = require("config.languages")

local function uniq(list)
  local seen, out = {}, {}
  for _, v in ipairs(list) do
    if not seen[v] then seen[v] = true; out[#out + 1] = v end
  end
  return out
end

--- Collect a list-valued field (e.g. "lsp") across every enabled language.
function M.collect(field)
  local out = {}
  for _, name in ipairs(M.settings.languages) do
    local p = presets[name]
    if not p then
      vim.schedule(function() vim.notify("Unknown language preset: " .. name, vim.log.levels.WARN) end)
    else
      local v = p[field]
      if type(v) == "string" then out[#out + 1] = v
      elseif type(v) == "table" then vim.list_extend(out, v) end
    end
  end
  return uniq(out)
end

--- Merge a filetype->tools map (formatters/linters) across enabled languages.
function M.collect_map(field)
  local out = {}
  for _, name in ipairs(M.settings.languages) do
    for ft, tools in pairs((presets[name] or {})[field] or {}) do out[ft] = tools end
  end
  return out
end

function M.feature(name) return M.settings.features[name] ~= false end
function M.icons() return M.settings.features.icons ~= false end

return M
