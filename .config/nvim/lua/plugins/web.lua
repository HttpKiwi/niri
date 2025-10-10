return {
  -- LSP Support
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- HTML LSP
        html = {
          filetypes = { "html" },
        },
        -- CSS LSP
        cssls = {
          filetypes = { "css", "scss", "less" },
        },
        -- JavaScript/TypeScript LSP
        tsserver = {
          filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
        },
      },
    },
  },

  -- Formatting
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        html = { "prettier" },
        css = { "prettier" },
        scss = { "prettier" },
        less = { "prettier" },
        javascript = { "prettier" },
        javascriptreact = { "prettier" },
        typescript = { "prettier" },
        typescriptreact = { "prettier" },
      },
    },
  },

  -- Mason will help install the required LSP servers and formatters
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        -- LSP
        "html-lsp",
        "css-lsp",
        "typescript-language-server",
        -- Formatters
        "prettier",
      },
    },
  },
}
