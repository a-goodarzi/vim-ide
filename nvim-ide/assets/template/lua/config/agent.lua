-- Agent status: shows what Claude Code is doing in the statusline and tells you when it needs you or has finished.
-- How it works: the IDE starts Claude with `--settings` carrying hooks (SessionStart, UserPromptSubmit, PreToolUse, Notification,
-- Stop, SessionEnd). Each hook runs extras/ide-agent-hook, which appends the event to a spool file; nvim watches that file.
-- Nothing in your own ~/.claude/settings.json is touched, and the hooks do nothing outside the IDE (no IDE_AGENT_SPOOL).
--   :IDEAgent  activity log (recent events)        Settings > Claude Code > Notify when Claude needs me / finishes
local M = {}
local uv = vim.uv or vim.loop

M.state = { status = "none", tool = nil, since = 0, message = nil }   -- none | idle | working | waiting | done
M.events = {}                                                          -- newest last, at most 100
local spool_dir = vim.fn.stdpath("state") .. "/ide-agent"
M.spool = spool_dir .. "/" .. vim.fn.getpid() .. ".jsonl"
local EVENTS = { "SessionStart", "UserPromptSubmit", "PreToolUse", "Notification", "Stop", "SessionEnd" }

function M.hook_path() return vim.fn.stdpath("config") .. "/extras/ide-agent-hook" end

--- The JSON given to `claude --settings`.
function M.settings_json()
  local hooks = {}
  for _, ev in ipairs(EVENTS) do hooks[ev] = { { hooks = { { type = "command", command = vim.fn.shellescape(M.hook_path()) } } } } end
  return vim.json.encode({ hooks = hooks })
end

--- Where the claude CLI lives: the setting, PATH, then the places the installers use (claudecode.nvim looks in the same places).
--- A bare "claude" would not be found by `env` when it is only an alias or lives in ~/.claude/local.
function M.claude_bin()
  local set = (require("config").settings.claude or {}).terminal_cmd
  if set and set ~= "" then return set end
  local found = vim.fn.exepath("claude")
  if found ~= "" then return vim.fn.shellescape(found) end
  for _, p in ipairs({ "~/.claude/local/claude", "~/.local/bin/claude", "~/.npm-global/bin/claude", "~/.volta/bin/claude", "/opt/homebrew/bin/claude", "/usr/local/bin/claude" }) do
    p = vim.fn.expand(p)
    if vim.fn.executable(p) == 1 then return vim.fn.shellescape(p) end
  end
  local ok, p = pcall(function() return require("config.path").find("claude") end)   -- ask the login shell
  return ok and p and vim.fn.shellescape(p) or nil
end

--- The full command the Claude panel runs, or nil to let claudecode.nvim use its own default (when claude cannot be located here).
function M.command()
  local base = M.claude_bin()
  if not base then return nil end
  M.start()
  local cp = require("config").feature("agent_checkpoints") and "IDE_AGENT_CHECKPOINT=1 " or ""
  return ("env IDE_AGENT_SPOOL=%s %s%s --settings %s"):format(vim.fn.shellescape(M.spool), cp, base, vim.fn.shellescape(M.settings_json()))
end

local function first_line(s, n)
  s = tostring(s or ""):gsub("%s+", " "):gsub("^ ", "")
  return #s > (n or 80) and (s:sub(1, (n or 80) - 1) .. "\xe2\x80\xa6") or s
end

local function focused_in_claude() return vim.bo.filetype == "snacks_terminal" end

--- Apply one spool line ("<unix time>\t<json>"). Exposed for the smoke test.
function M.handle(line)
  local ts, json = line:match("^(%d+)\t(.*)$")
  if not json then return end
  local ok, e = pcall(vim.json.decode, json)
  if not (ok and type(e) == "table") then return end
  local ev, st, msg = e.hook_event_name, M.state, nil
  if ev == "UserPromptSubmit" then st.status, st.tool = "working", nil
  elseif ev == "PreToolUse" then st.status, st.tool = "working", e.tool_name
  elseif ev == "Notification" then
    msg = first_line(e.message)
    local kind = tostring(e.notification_type or "")
    st.status = kind:find("idle") and "idle" or "waiting"
  elseif ev == "Stop" then st.status, st.tool, msg = "done", nil, first_line(e.last_assistant_message)
  elseif ev == "SessionStart" then st.status, st.tool = "idle", nil
  elseif ev == "SessionEnd" then st.status, st.tool = "none", nil
  else return end
  st.since, st.message = tonumber(ts) or os.time(), msg
  M.events[#M.events + 1] = { ts = st.since, event = ev, tool = e.tool_name, message = msg, session = e.session_id }
  while #M.events > 100 do table.remove(M.events, 1) end
  local notify = (require("config").settings.claude or {}).notify ~= false
  if notify and not focused_in_claude() then
    if st.status == "waiting" then vim.notify("Claude needs you" .. (msg and (": " .. msg) or ""), vim.log.levels.WARN, { title = "Claude Code" })
    elseif ev == "Stop" then vim.notify("Claude finished" .. (msg and (": " .. msg) or ""), vim.log.levels.INFO, { title = "Claude Code" }) end
  end
  vim.cmd.redrawstatus()
end

-- ── watching the spool file ───────────────────────────────────────────────────────────────────────
local offset, watcher = 0, nil
local function read_new()
  local fd = uv.fs_open(M.spool, "r", 438)
  if not fd then return end
  local stat = uv.fs_fstat(fd)
  if stat and stat.size > offset then
    local data = uv.fs_read(fd, stat.size - offset, offset) or ""
    offset = stat.size
    for line in data:gmatch("[^\n]+") do pcall(M.handle, line) end
  end
  uv.fs_close(fd)
end

function M.start()
  if watcher then return end
  vim.fn.mkdir(spool_dir, "p")
  -- spool files of nvim instances that no longer exist (older than a day)
  for _, f in ipairs(vim.fn.glob(spool_dir .. "/*.jsonl", false, true)) do
    local s = uv.fs_stat(f)
    if s and s.mtime.sec < os.time() - 86400 then os.remove(f) end
  end
  local f = io.open(M.spool, "w"); if f then f:close() end
  offset = 0
  watcher = uv.new_fs_event()
  if watcher then
    watcher:start(M.spool, {}, vim.schedule_wrap(function() read_new() end))
  end
  vim.api.nvim_create_autocmd("VimLeavePre", { once = true, callback = function() pcall(os.remove, M.spool) end })
end

--- For the statusline: { text, bg } or nil when there is nothing to show.
function M.segment(icons, P)
  local st = M.state
  if st.status == "working" then return { text = (icons and "\xe2\x97\x8f " or "") .. "Claude" .. (st.tool and (": " .. st.tool) or " working"), bg = P.pos }
  elseif st.status == "waiting" then return { text = (icons and "\xef\x81\xaa " or "! ") .. "Claude needs you", bg = P.warn }
  elseif st.status == "done" and os.time() - st.since < 120 then return { text = (icons and "\xe2\x9c\x93 " or "") .. "Claude done", bg = P.lsp } end
end

-- ── activity page ─────────────────────────────────────────────────────────────────────────────────
local ui = require("config.ui")
local page = ui.page({
  name = "Claude activity", ft = "ide-agent",
  render = function(_, b)
    local st = M.state
    b:title("Claude activity", "What Claude Code did in this IDE's panel. r refreshes, c clears, q closes.")
    local chip = { working = { " working ", "IDEChipSel" }, waiting = { " needs you ", "IDEChipWarn" }, done = { " done ", "IDEChipOn" },
      idle = { " idle ", "IDEChip" }, none = { " no session ", "IDEChipOff" } }
    local c = chip[st.status] or chip.none
    local l = b:add(b.margin .. c[1] .. "  " .. (st.tool and ("running " .. st.tool) or (st.message or "")), nil)
    b:span(l, #b.margin, #b.margin + #c[1], c[2])
    b:blank()
    if #M.events == 0 then
      b:add(b.margin .. "No events yet. Open Claude with <Space>ac and send a prompt.", "IDEMuted")
      b:add(b.margin .. "Events only come from the IDE's own Claude panel (it starts Claude with hooks).", "IDEMuted")
    end
    for i = #M.events, 1, -1 do
      local e = M.events[i]
      local when = os.date("%H:%M:%S", e.ts)
      b:add(b.margin .. ui.pad(when, 10) .. ui.pad(e.event, 18) .. ui.pad(e.tool or "", 12) .. (e.message or ""), i == #M.events and nil or "IDEMuted")
    end
  end,
  keys = {
    r = function(p) p:render() end,
    c = function(p) M.events = {}; p:render() end,
  },
})
function M.open() page:open() end
vim.api.nvim_create_user_command("IDEAgent", M.open, { desc = "Claude activity log" })
return M
