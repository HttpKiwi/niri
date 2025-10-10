return {
  -- Dart language support
  {
    "dart-lang/dart-vim-plugin",
    event = "VeryLazy",
    ft = { "dart" },
  },
  -- Dart formatting is configured in conform.lua
  -- Dart snippets
  {
    "L3MON4D3/LuaSnip",
    dependencies = {
      "rafamadriz/friendly-snippets",
    },
    config = function()
      require("luasnip.loaders.from_vscode").lazy_load({
        paths = { "/opt/flutter/bin/cache/dart-sdk/snippets" },
      })
    end,
  },
  -- Dart specific keymaps
  {
    "LazyVim/LazyVim",
    opts = {
      keys = {
        {
          "<leader>cd",
          function()
            vim.cmd("!dart format %")
          end,
          desc = "Format Dart file",
        },
        {
          "<leader>cD",
          function()
            vim.cmd("!dart analyze %")
          end,
          desc = "Analyze Dart file",
        },
      },
    },
  },
}

