return {
  { "saghen/blink.cmp", version = "1.*", event = "InsertEnter",
    dependencies = { "rafamadriz/friendly-snippets" },
    opts = {
      -- default preset: <C-space> open, <C-y> accept, <C-n>/<C-p> select, <C-e> close.
      -- Change to "super-tab" if you want Tab to accept.
      keymap = { preset = "default" },
      completion = { menu = { border = "rounded" }, documentation = { auto_show = true, auto_show_delay_ms = 300, window = { border = "rounded" } } },
      sources = { default = { "lsp", "path", "snippets", "buffer" } },
      signature = { enabled = true, window = { border = "rounded" } },
    } },
}
