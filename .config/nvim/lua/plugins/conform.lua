return {
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        dart = { "dart_format" },
      },
      formatters = {
        dart_format = {
          command = "dart",
          args = { "format" },
          stdin = true,
        },
      },
    },
  },
}

