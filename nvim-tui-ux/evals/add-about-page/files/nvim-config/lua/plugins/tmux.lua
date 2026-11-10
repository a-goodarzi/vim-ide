-- tmux integration. Active only when running inside tmux ($TMUX set).
-- Pair it with extras/tmux.conf (see references/tmux.md). Ctrl-h/j/k/l then move across
-- nvim splits AND tmux panes. Inside terminal buffers (Claude panel) use Alt-h/j/k/l.
local inside = vim.env.TMUX ~= nil
local function nav(key, cmd) return { key, "<cmd>" .. cmd .. "<cr>", desc = "Navigate (nvim/tmux)", silent = true } end
return {
  { "christoomey/vim-tmux-navigator", cond = inside,
    init = function() vim.g.tmux_navigator_no_mappings = 1 end, -- we bind explicitly; keeps <C-\> free
    cmd = { "TmuxNavigateLeft", "TmuxNavigateDown", "TmuxNavigateUp", "TmuxNavigateRight" },
    keys = { nav("<C-h>", "TmuxNavigateLeft"), nav("<C-j>", "TmuxNavigateDown"),
      nav("<C-k>", "TmuxNavigateUp"), nav("<C-l>", "TmuxNavigateRight") } },
}
