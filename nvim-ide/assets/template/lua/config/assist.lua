-- Snippet browser and "ask Claude" helpers.
--   palette > "Snippets..." lists the snippets for the current file type (friendly-snippets) and inserts the one you pick.
--   palette > "Claude: ask about selection / file" sends the selection (or file) as context and focuses the Claude panel.
local M = {}

local function snippet_files(ft)
  local base = vim.fn.stdpath("data") .. "/lazy/friendly-snippets"
  local pj = base .. "/package.json"
  local f = io.open(pj, "r"); if not f then return {} end
  local txt = f:read("*a"); f:close()
  local ok, d = pcall(vim.json.decode, txt)
  if not ok then return {} end
  local files = {}
  for _, s in ipairs(d.contributes and d.contributes.snippets or {}) do
    local langs = type(s.language) == "table" and s.language or { s.language }
    if vim.tbl_contains(langs, ft) then files[#files + 1] = base .. "/" .. s.path:gsub("^%./", "") end
  end
  return files
end

function M.snippets()
  local ft = vim.bo.filetype
  local items = {}
  for _, p in ipairs(snippet_files(ft)) do
    local f = io.open(p, "r")
    if f then
      local ok, d = pcall(vim.json.decode, f:read("*a")); f:close()
      if ok and type(d) == "table" then
        for name, sn in pairs(d) do
          local body = type(sn.body) == "table" and table.concat(sn.body, "\n") or sn.body
          local prefix = type(sn.prefix) == "table" and sn.prefix[1] or sn.prefix
          if body then items[#items + 1] = { name = name, prefix = prefix or "", body = body, desc = sn.description or "" } end
        end
      end
    end
  end
  if #items == 0 then return vim.notify("No snippets for filetype '" .. ft .. "'.") end
  table.sort(items, function(a, b) return a.name < b.name end)
  vim.ui.select(items, { prompt = "Snippets (" .. ft .. ")", format_item = function(i) return ("%-14s %s"):format(i.prefix, i.name) end },
    function(c) if c then vim.snippet.expand(c.body) end end)
end

function M.ask_selection()
  local mode = vim.fn.mode()
  if mode:find("[vV\22]") then
    vim.cmd("ClaudeCodeSend")
  elseif vim.fn.line("'<") > 0 and vim.fn.line("'<") <= vim.fn.line("$") then
    vim.cmd("'<,'>ClaudeCodeSend")      -- the last visual selection
  else
    vim.cmd("ClaudeCodeAdd %")
  end
  vim.defer_fn(function() pcall(vim.cmd, "ClaudeCodeFocus") end, 200)
end

vim.api.nvim_create_user_command("IDESnippets", M.snippets, { desc = "Browse snippets for this file type" })
return M
