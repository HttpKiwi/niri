return {
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        dart = { "dart_format" },
        lua = { "stylua" },
      },
      formatters = {
        dart_format = {
          command = "dart",
          args = { "format" },
          stdin = true,
        },
        stylua = {
          command = "stylua",
          args = { "-" },
          stdin = true,
        },
      },
    },
  },
}

