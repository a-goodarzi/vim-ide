local on = require("config").feature("git")
return {
  { "lewis6991/gitsigns.nvim", enabled = on, event = "BufReadPre",
    opts = { on_attach = function(buf)
      local gs = require("gitsigns")
      local m = function(lhs, rhs, desc) vim.keymap.set("n", lhs, rhs, { buffer = buf, desc = desc }) end
      m("]h", function() gs.nav_hunk("next") end, "Next hunk")
      m("[h", function() gs.nav_hunk("prev") end, "Prev hunk")
      m("<leader>gs", gs.stage_hunk, "Stage hunk")
      m("<leader>gr", gs.reset_hunk, "Reset hunk")
      m("<leader>gp", gs.preview_hunk, "Preview hunk")
      m("<leader>gb", gs.blame_line, "Blame line")
      m("<leader>gd", gs.diffthis, "Diff this")
    end } },
  { "sindrets/diffview.nvim", enabled = on, cmd = { "DiffviewOpen", "DiffviewFileHistory" },
    keys = { { "<leader>gv", "<cmd>DiffviewOpen<cr>", desc = "Diff view" }, { "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", desc = "File history" } } },
}
