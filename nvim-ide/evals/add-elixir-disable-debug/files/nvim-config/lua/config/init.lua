-- Shared helpers: loads settings and resolves language presets into flat lists.
local M = {}

M.settings = require("config.settings")
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
