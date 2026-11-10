local cfg = require("config")
local servers = cfg.collect("lsp")
local tools = cfg.collect("mason")

return {
  { "neovim/nvim-lspconfig", event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      { "mason-org/mason.nvim", cmd = "Mason", build = ":MasonUpdate", opts = { ui = { border = "rounded", width = 0.85, height = 0.85 } } },
      "mason-org/mason-lspconfig.nvim",
      "WhoIsSethDaniel/mason-tool-installer.nvim",
      "saghen/blink.cmp",
    },
    config = function()
      vim.diagnostic.config({
        severity_sort = true, virtual_text = { spacing = 2, prefix = "●" },
        float = { border = "rounded", source = true },
      })

      -- Capabilities from the completion engine apply to every server.
      vim.lsp.config("*", { capabilities = require("blink.cmp").get_lsp_capabilities() })

      -- Sensible defaults + user overrides from settings.lua
      vim.lsp.config("lua_ls", { settings = { Lua = { diagnostics = { globals = { "vim" } }, workspace = { checkThirdParty = false }, telemetry = { enable = false } } } })
      for name, conf in pairs(cfg.settings.lsp_overrides or {}) do vim.lsp.config(name, conf) end

      -- Installs servers via Mason and calls vim.lsp.enable() for each.
      -- Mason also installs formatters (stylua...) that lspconfig knows as servers; keep them out so the
      -- formatter plugin (conform) is the only thing formatting, not two tools at once.
      require("mason-lspconfig").setup({ ensure_installed = servers, automatic_enable = { exclude = { "stylua" } } })
      require("mason-tool-installer").setup({ ensure_installed = tools })

      vim.api.nvim_create_autocmd("LspAttach", { callback = function(ev)
        local m = function(lhs, rhs, desc, mode) vim.keymap.set(mode or "n", lhs, rhs, { buffer = ev.buf, desc = desc }) end
        local b = vim.lsp.buf
        m("gd", b.definition, "Go to definition")
        m("gD", b.declaration, "Go to declaration")
        m("gr", b.references, "References")
        m("gi", b.implementation, "Implementation")
        m("gy", b.type_definition, "Type definition")
        m("K", function() b.hover() end, "Hover")
        m("<leader>ca", b.code_action, "Code action", { "n", "x" })
        m("<leader>cr", b.rename, "Rename")
        m("<leader>cs", b.signature_help, "Signature help")
        m("<leader>uh", function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = ev.buf }), { bufnr = ev.buf }) end, "Toggle inlay hints")
      end })
    end },
}
