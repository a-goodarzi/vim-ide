-- Self-contained statusline (no lualine). Deterministic, live-switchable, themed from the colorscheme.
--   rounded   : separate pills with round caps, like powerlevel10k
--   powerline : contiguous segments joined by arrows, with correct foreground/background transitions
--   plain     : text only
-- Switch live with require("config.statusline").apply() after changing settings.statusline_style.
local M = {}

local G = { -- powerline glyphs (UTF-8 bytes; LuaJIT has no \u{} escape). ui-lint: ok (render() falls back to plain when icons are off)
  cap_l = "\xee\x82\xb6", cap_r = "\xee\x82\xb4",     -- ui-lint: ok  U+E0B6 / U+E0B4 round caps
  arrow_r = "\xee\x82\xb0", arrow_l = "\xee\x82\xb2", -- ui-lint: ok  U+E0B0 / U+E0B2 solid arrows
  branch = "\xee\x9c\xa5", lsp = "\xef\x82\x85", clock = "\xef\x80\x97", file = "\xef\x85\x9b", -- ui-lint: ok
  err = "\xef\x81\x97", warn = "\xef\x81\xb1", info = "\xef\x81\x9a", pos = "\xee\x82\xa1", -- ui-lint: ok
}

local function hl(name)
  local ok, h = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
  return ok and h or {}
end
local function hex(n, fallback) return n and string.format("#%06x", n) or fallback end

-- palette derived from the current colorscheme -------------------------------------------------
local P = {}
local function build_palette()
  local normal, sl = hl("Normal"), hl("StatusLine")
  P.base_bg = hex(sl.bg, nil) or hex(normal.bg, "#1e1e2e")
  P.dark = hex(normal.bg, "#1e1e2e")                    -- text on bright segments
  P.text = hex(normal.fg, "#c0caf5")
  local function accent(g, fb) return hex(hl(g).fg, fb) end
  P.mode = {
    n = accent("Function", "#7aa2f7"), i = accent("String", "#9ece6a"), v = accent("Statement", "#bb9af7"),
    R = accent("DiagnosticError", "#f7768e"), c = accent("Constant", "#e0af68"), t = accent("DiagnosticOk", "#73daca"),
  }
  P.dim1 = hex(hl("CursorLine").bg, nil) or hex(hl("Pmenu").bg, "#2a2e45")
  P.dim2 = hex(hl("Visual").bg, "#3b4261")
  P.warn = accent("DiagnosticWarn", "#e0af68")
  P.err = accent("DiagnosticError", "#f7768e")
  P.lsp = accent("String", "#9ece6a")
  P.pos = accent("Special", "#7dcfff")
end

local defined = {}
local function group(fg, bg, bold)
  local name = "IdeSl_" .. (fg or "n"):gsub("#", "") .. "_" .. (bg or "n"):gsub("#", "") .. (bold and "b" or "")
  if not defined[name] then
    vim.api.nvim_set_hl(0, name, { fg = fg, bg = bg, bold = bold })
    defined[name] = true
  end
  return "%#" .. name .. "#"
end

-- segments -------------------------------------------------------------------------------------
local mode_names = { n = "NORMAL", i = "INSERT", v = "VISUAL", V = "V-LINE", ["\22"] = "V-BLOCK", R = "REPLACE",
  c = "COMMAND", t = "TERMINAL", s = "SELECT", S = "S-LINE", no = "OP" }
local function mode_key() local m = vim.fn.mode(1):sub(1, 1); return (m == "V" or m == "\22") and "v" or (m == "s" and "v" or m) end

local function lsp_name()
  local c = vim.lsp.get_clients({ bufnr = 0 })
  return #c > 0 and c[1].name or nil
end
local function diag_text(icons)
  local d = vim.diagnostic.count(0)
  local e, w = d[vim.diagnostic.severity.ERROR] or 0, d[vim.diagnostic.severity.WARN] or 0
  if e + w == 0 then return nil end
  local parts = {}
  if e > 0 then parts[#parts + 1] = (icons and G.err .. " " or "E:") .. e end
  if w > 0 then parts[#parts + 1] = (icons and G.warn .. " " or "W:") .. w end
  return table.concat(parts, " "), e > 0 and P.err or P.warn
end

--- Ordered segments for the current window.
local function segments(icons)
  local mk = mode_key()
  local mcol = P.mode[mk] or P.mode.n
  local left, right = {}, {}
  left[#left + 1] = { text = (mode_names[vim.fn.mode(1):sub(1, 1)] or "NORMAL"), bg = mcol, fg = P.dark, bold = true }
  local br = vim.b.gitsigns_head
  if br and br ~= "" then left[#left + 1] = { text = (icons and G.branch .. " " or "") .. br, bg = P.dim2, fg = P.text } end
  left[#left + 1] = { text = (icons and G.file .. " " or "") .. "%f%m", bg = P.dim1, fg = P.text }
  local dt, dcol = diag_text(icons)
  if dt then left[#left + 1] = { text = dt, bg = dcol, fg = P.dark } end

  local ag = require("config").feature("agent_status") and require("config.agent").segment(icons, P)
  if ag then right[#right + 1] = { text = ag.text, bg = ag.bg, fg = P.dark, bold = true } end
  local ln = lsp_name()
  if ln then right[#right + 1] = { text = (icons and G.lsp .. " " or "") .. ln, bg = P.lsp, fg = P.dark } end
  local ft = vim.bo.filetype ~= "" and vim.bo.filetype or "no ft"
  right[#right + 1] = { text = ft, bg = P.dim1, fg = P.text }
  right[#right + 1] = { text = (icons and G.pos .. " " or "") .. "%l:%c  %p%%", bg = P.pos, fg = P.dark }
  right[#right + 1] = { text = (icons and G.clock .. " " or "") .. os.date("%H:%M"), bg = P.dim2, fg = P.text }
  return left, right
end

-- renderers -------------------------------------------------------------------------------------
local function render_plain(left, right)
  local function join(list) local t = {}; for _, s in ipairs(list) do t[#t + 1] = s.text end; return table.concat(t, " \xe2\x94\x82 ") end
  local out = { group(left[1].bg, P.base_bg, true), " " .. left[1].text, group(P.text, P.base_bg), " " }
  local rest = {}; for i = 2, #left do rest[#rest + 1] = left[i] end
  out[#out + 1] = join(rest)
  out[#out + 1] = "%="
  out[#out + 1] = group(P.text, P.base_bg) .. join(right) .. " "
  return table.concat(out)
end

local function render_rounded(left, right)
  local out = {}
  local function pill(s)
    return group(s.bg, P.base_bg) .. G.cap_l .. group(s.fg, s.bg, s.bold) .. " " .. s.text .. " " .. group(s.bg, P.base_bg) .. G.cap_r
  end
  for _, s in ipairs(left) do out[#out + 1] = pill(s) .. group(P.text, P.base_bg) .. " " end
  out[#out + 1] = group(P.text, P.base_bg) .. "%="
  for i, s in ipairs(right) do out[#out + 1] = pill(s) .. (i < #right and group(P.text, P.base_bg) .. " " or "") end
  return table.concat(out)
end

local function render_powerline(left, right)
  local out = {}
  for i, s in ipairs(left) do
    out[#out + 1] = group(s.fg, s.bg, s.bold) .. " " .. s.text .. " "
    local nxt = left[i + 1]
    -- arrow: foreground = this segment's bg, background = next segment's bg (or the bar)
    out[#out + 1] = group(s.bg, nxt and nxt.bg or P.base_bg) .. G.arrow_r
  end
  out[#out + 1] = group(P.text, P.base_bg) .. "%="
  for i, s in ipairs(right) do
    local prev = right[i - 1]
    -- arrow pointing left: foreground = this segment's bg, background = previous segment's bg (or the bar)
    out[#out + 1] = group(s.bg, prev and prev.bg or P.base_bg) .. G.arrow_l
    out[#out + 1] = group(s.fg, s.bg, s.bold) .. " " .. s.text .. " "
  end
  return table.concat(out)
end

--- Called by 'statusline' via %!v:lua... on every redraw.
function M.render()
  if vim.bo.filetype == "snacks_dashboard" then return "" end
  local cfg = require("config")
  local icons = cfg.icons()
  local style = cfg.settings.statusline_style or "rounded"
  if not icons then style = "plain" end
  if not P.base_bg then build_palette() end
  local ok, res = pcall(function()
    local l, r = segments(icons)
    if style == "powerline" then return render_powerline(l, r)
    elseif style == "plain" then return render_plain(l, r)
    else return render_rounded(l, r) end
  end)
  return ok and res or "%f%m %= %l:%c"
end

--- Rebuild colors (after a colorscheme/style change) and redraw. Safe to call any time.
function M.apply()
  defined = {}
  build_palette()
  vim.o.statusline = "%!v:lua.require'config.statusline'.render()"
  vim.cmd("redrawstatus!")
end

function M.setup()
  vim.o.laststatus = 3
  M.apply()
  local g = vim.api.nvim_create_augroup("ide-statusline", { clear = true })
  vim.api.nvim_create_autocmd("ColorScheme", { group = g, callback = function() M.apply() end })
  vim.api.nvim_create_autocmd({ "ModeChanged", "DiagnosticChanged", "LspAttach", "LspDetach", "BufEnter" },
    { group = g, callback = function() vim.cmd("redrawstatus") end })
  -- clock tick
  local t = vim.uv.new_timer()
  t:start(30000, 30000, vim.schedule_wrap(function() vim.cmd("redrawstatus") end))
end

return M
