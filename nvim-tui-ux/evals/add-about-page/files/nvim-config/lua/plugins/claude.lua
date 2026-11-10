-- Claude Code embedded in a side panel. Requires the `claude` CLI on PATH
-- (npm i -g @anthropic-ai/claude-code, or set claude.terminal_cmd in settings).
-- claudecode.nvim speaks the same protocol as the VS Code extension: Claude sees your
-- open file / selection and its edits open as accept/deny diffs inside nvim.
local cfg = require("config")
local c = cfg.settings.claude or {}
return {
  { "coder/claudecode.nvim", enabled = cfg.feature("claude"), dependencies = { "folke/snacks.nvim" },
    cmd = { "ClaudeCode", "ClaudeCodeFocus", "ClaudeCodeSelectModel", "ClaudeCodeAdd", "ClaudeCodeSend",
      "ClaudeCodeTreeAdd", "ClaudeCodeStatus", "ClaudeCodeStart", "ClaudeCodeStop", "ClaudeCodeOpen",
      "ClaudeCodeClose", "ClaudeCodeDiffAccept", "ClaudeCodeDiffDeny", "ClaudeCodeCloseAllDiffs" },
    keys = {
      { "<leader>ac", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude" },
      { "<A-c>", "<cmd>ClaudeCodeFocus<cr>", mode = { "n", "t" }, desc = "Focus Claude (works in tmux)" },
      { "<leader>af", "<cmd>ClaudeCodeFocus<cr>", desc = "Focus Claude" },
      { "<leader>ar", "<cmd>ClaudeCode --resume<cr>", desc = "Resume conversation" },
      { "<leader>aC", "<cmd>ClaudeCode --continue<cr>", desc = "Continue last conversation" },
      { "<leader>am", "<cmd>ClaudeCodeSelectModel<cr>", desc = "Select model" },
      { "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>", desc = "Add current file to context" },
      { "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send selection to Claude" },
      { "<leader>as", "<cmd>ClaudeCodeTreeAdd<cr>", desc = "Add file from explorer",
        ft = { "neo-tree", "NvimTree", "oil" } },
      { "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept diff" },
      { "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Deny diff" },
    },
    opts = function()
      return {
        terminal_cmd = c.terminal_cmd,
        terminal = { split_side = c.side or "right", split_width_percentage = c.width or 0.35, provider = "auto" },
      }
    end },
}
