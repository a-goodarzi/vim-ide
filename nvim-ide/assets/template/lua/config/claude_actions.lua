-- Claude actions: send the right context to Claude with one key, and one-shot helpers that use `claude -p`.
--   <Space>ax fix the problem under the cursor     <Space>ae explain (line / selection)   <Space>aT write tests (selection / file)
--   <Space>aL send the last terminal output        <Space>aR review the staged diff       <Space>ag commit message from the staged diff
--   <Space>aP pull request description for this branch
-- "Send" actions type the prompt into the Claude panel (as a paste) and leave Enter to you, so you read it first.
-- Commit message and PR description run `claude -p` in the background and need no panel.
local M = {}

local MAX = 30000      -- characters of diff / output sent along

local function cfg() return require("config").settings.claude or {} end
local function rel(path) return vim.fn.fnamemodify(path, ":.") end
local function clip(s) s = tostring(s or ""); return #s > MAX and (s:sub(1, MAX) .. "\n… (cut)") or s end
local function fence(text, ft) return "```" .. (ft or "") .. "\n" .. text .. "\n```" end

-- ── prompts (pure functions, easy to test) ────────────────────────────────────────────────────────
local SEV = { "error", "warning", "info", "hint" }

--- The diagnostics on the cursor line (or the nearest one), as a prompt. nil when there is none.
function M.diagnostic_prompt(buf, lnum)
  buf = buf or 0
  local ds = vim.diagnostic.get(buf, { lnum = lnum })
  if #ds == 0 then ds = vim.diagnostic.get(buf, {}); table.sort(ds, function(a, b) return math.abs(a.lnum - lnum) < math.abs(b.lnum - lnum) end); ds = { ds[1] } end
  if not ds[1] then return nil end
  local name = rel(vim.api.nvim_buf_get_name(buf))
  local parts = {}
  for _, d in ipairs(ds) do parts[#parts + 1] = ("- %s:%d: %s%s (%s)"):format(name, d.lnum + 1, SEV[d.severity] or "problem", "", (d.message or ""):gsub("\n.*", "")) end
  return "Fix this problem in the project. Explain the cause in one sentence, then make the change.\n" .. table.concat(parts, "\n")
end

--- The lines of a command range (:'<,'>Cmd), or nil when the command had no range.
local function range_text(o)
  if o and o.range and o.range > 0 then return table.concat(vim.api.nvim_buf_get_lines(0, o.line1 - 1, o.line2, false), "\n") end
end

function M.explain_prompt(text, name, ft) return ("Explain this code from %s. Be concise and mention anything surprising.\n%s"):format(name, fence(text, ft)) end
function M.tests_prompt(text, name, ft) return ("Write tests for this code from %s, in the style of the existing tests in the project (find them first).\n%s"):format(name, fence(text, ft)) end
function M.review_prompt(diff) return "Review this staged diff. List bugs, risky changes and missing tests first; skip style nitpicks.\n" .. fence(clip(diff), "diff") end

-- ── sending to the Claude panel ───────────────────────────────────────────────────────────────────
local function claude_channel()
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(b) and vim.bo[b].filetype == "snacks_terminal" and vim.bo[b].buftype == "terminal" then
      local ch = vim.bo[b].channel
      if ch and ch > 0 then return ch end
    end
  end
end
M.channel = claude_channel

--- Type `text` into the Claude panel (opening it first when needed). Enter is left to the user.
function M.send(text)
  local function go(ch)
    vim.api.nvim_chan_send(ch, "\27[200~" .. text .. "\27[201~")      -- a bracketed paste: newlines do not submit
    pcall(vim.cmd, "ClaudeCodeFocus")
    vim.notify("Prompt typed into Claude: read it, then press Enter.", vim.log.levels.INFO, { title = "Claude" })
  end
  local ch = claude_channel()
  if ch then return go(ch) end
  pcall(vim.cmd, "ClaudeCode")
  local tries = 0
  local function retry()
    tries = tries + 1
    local c = claude_channel()
    if c then vim.defer_fn(function() go(c) end, 600) elseif tries < 15 then vim.defer_fn(retry, 300)
    else vim.fn.setreg("+", text); vim.notify("Could not reach the Claude panel; the prompt is on your clipboard.", vim.log.levels.WARN) end
  end
  vim.defer_fn(retry, 500)
end

-- ── send actions ──────────────────────────────────────────────────────────────────────────────────
function M.fix()
  local p = M.diagnostic_prompt(0, vim.api.nvim_win_get_cursor(0)[1] - 1)
  if not p then return vim.notify("No problem found in this file.") end
  M.send(p)
end
function M.explain(o)
  local text = range_text(o) or vim.api.nvim_get_current_line()
  M.send(M.explain_prompt(text, rel(vim.api.nvim_buf_get_name(0)), vim.bo.filetype))
end
function M.tests(o)
  local text = range_text(o) or table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
  M.send(M.tests_prompt(text, rel(vim.api.nvim_buf_get_name(0)), vim.bo.filetype))
end
function M.terminal_output()
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[b].buftype == "terminal" and vim.bo[b].filetype ~= "snacks_terminal" then
      local lines = vim.api.nvim_buf_get_lines(b, 0, -1, false)
      while #lines > 0 and lines[#lines]:match("^%s*$") do table.remove(lines) end
      local last = {}
      for i = math.max(#lines - 80, 1), #lines do last[#last + 1] = lines[i] end
      if #last > 0 then return M.send("This is the output of my last terminal command. Find what went wrong and fix it.\n" .. fence(clip(table.concat(last, "\n")))) end
    end
  end
  vim.notify("No terminal output found: open the terminal panel (Alt-t) and run something first.")
end

-- ── one-shot helpers with `claude -p` ─────────────────────────────────────────────────────────────
--- Replaceable in tests: runner(args, stdin, callback(ok, text_or_error))
function M.runner(args, stdin, cb)
  local base = vim.split(cfg().terminal_cmd or "claude", "%s+", { trimempty = true })
  local cmd = vim.list_extend(vim.list_slice(base), args)
  local ok, err = pcall(vim.system, cmd, { stdin = stdin, text = true, timeout = 180000 }, function(r)
    vim.schedule(function()
      if r.code == 0 and vim.trim(r.stdout or "") ~= "" then cb(true, vim.trim(r.stdout)) else cb(false, vim.trim(r.stderr ~= "" and r.stderr or ("claude exited with " .. tostring(r.code)))) end
    end)
  end)
  if not ok then vim.schedule(function() cb(false, "could not start claude: " .. tostring(err)) end) end
end

function M.ask(prompt, stdin, cb) M.runner({ "-p", prompt, "--max-turns", "1", "--no-session-persistence" }, stdin, cb) end

local function git_out(root, args) local r = vim.system(vim.list_extend({ "git", "-C", root }, args), { text = true }):wait(); return r.code == 0 and r.stdout or "" end

function M.commit_message_prompt() return "Write a git commit message for this diff: an imperative subject line of at most 72 characters, then (only if useful) a blank line and a short body. Output the message only, no quotes or code fences." end

--- Fill the Source Control commit box with a message written from the staged diff.
function M.commit_message()
  local scm = require("config.scm")
  local root = scm.root or vim.trim(vim.fn.system({ "git", "rev-parse", "--show-toplevel" }))
  local diff = git_out(root, { "diff", "--cached" })
  if vim.trim(diff) == "" then diff = git_out(root, { "diff" }) end
  if vim.trim(diff) == "" then return vim.notify("Nothing to describe: stage some changes first.", vim.log.levels.WARN) end
  vim.notify("Claude is writing a commit message...", vim.log.levels.INFO, { title = "Source Control" })
  M.ask(M.commit_message_prompt(), clip(diff), function(ok, text)
    if not ok then return vim.notify("Commit message failed: " .. text, vim.log.levels.ERROR, { title = "Source Control" }) end
    text = text:gsub("^```%w*\n", ""):gsub("\n```$", "")
    scm.msg = text; pcall(scm.refresh)
    vim.notify("Commit message ready: edit it (m) or commit (c).", vim.log.levels.INFO, { title = "Source Control" })
  end)
end

function M.pr_description()
  local root = vim.trim(vim.fn.system({ "git", "rev-parse", "--show-toplevel" }))
  local base
  for _, b in ipairs({ "origin/main", "origin/master", "main", "master" }) do
    if vim.system({ "git", "-C", root, "rev-parse", "-q", "--verify", b }, { text = true }):wait().code == 0 then base = b break end
  end
  if not base then return vim.notify("No main / master branch to compare with.", vim.log.levels.WARN) end
  local diff = git_out(root, { "diff", base .. "...HEAD" })
  local log = git_out(root, { "log", "--oneline", base .. "..HEAD" })
  if vim.trim(diff) == "" then return vim.notify("This branch has no changes against " .. base .. ".") end
  vim.notify("Claude is writing the pull request description...", vim.log.levels.INFO, { title = "Claude" })
  M.ask("Write a pull request title and description (Markdown: Summary, Changes, Testing) for these commits and this diff.\nCommits:\n" .. log, clip(diff), function(ok, text)
    if not ok then return vim.notify("PR description failed: " .. text, vim.log.levels.ERROR) end
    vim.cmd("botright vnew"); vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(text, "\n"))
    vim.bo.filetype = "markdown"; vim.bo.buftype = "nofile"; vim.bo.bufhidden = "wipe"
    pcall(vim.api.nvim_buf_set_name, 0, "PR description")
  end)
end

function M.review_staged()
  local root = vim.trim(vim.fn.system({ "git", "rev-parse", "--show-toplevel" }))
  local diff = git_out(root, { "diff", "--cached" })
  if vim.trim(diff) == "" then return vim.notify("Nothing is staged.") end
  M.send(M.review_prompt(diff))
end

local cmds = { IDEClaudeFix = M.fix, IDEClaudeExplain = M.explain, IDEClaudeTests = M.tests, IDEClaudeTerminal = M.terminal_output,
  IDEClaudeReview = M.review_staged, IDECommitMessage = M.commit_message, IDEPRDescription = M.pr_description }
for name, fn in pairs(cmds) do
  vim.api.nvim_create_user_command(name, function(o) fn(o) end, { range = true, desc = "Claude: " .. name:gsub("^IDE", "") })
end
return M
