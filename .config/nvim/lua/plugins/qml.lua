return {
  -- Configure LSP for QML
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        qmlls = {
          cmd = { "/home/httpkiwi/.local/share/nvim/mason/bin/qmlls", "-E" },
          filetypes = { "qml" },
          root_dir = function(fname)
            return require("lspconfig.util").root_pattern("*.qmlproject", "*.pro", "CMakeLists.txt", ".git")(fname)
          end,
          init_options = {
            generateQmllsIni = true,
            qmllsIniDirectory = vim.fn.getcwd(),
          },
          settings = {
            qmlls = {
              buildDir = vim.fn.getcwd() .. "/build",
              importPaths = {
                vim.fn.getcwd(),
                "/usr/lib/qt6/qml",
                "/usr/lib/qt5/qml",
              },
            },
          },
        },
      },
    },
  },
  -- Configure formatting with conform.nvim
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        qml = { "qmlformat" },
      },
      formatters = {
        qmlformat = {
          command = "qmlformat",
          args = { "--inplace", "$FILENAME" },
          stdin = false,
        },
      },
    },
  },
  -- Configure linting with nvim-lint
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters_by_ft = {
        qml = { "qmllint" },
      },
      linters = {
        qmllint = {
          cmd = "qmllint",
          stdin = false,
          args = { "--silent" },
          ignore_exitcode = true,
          parser = require("lint.parser").from_pattern(
            [[(%d+):(%d+): (%w+): (.+)]],
            { "lnum", "col", "severity", "message" },
            { Warning = vim.diagnostic.severity.WARN, Error = vim.diagnostic.severity.ERROR }
          ),
        },
      },
    },
  },
  -- Add QML treesitter support
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      if type(opts.ensure_installed) == "table" then
        vim.list_extend(opts.ensure_installed, { "qmljs" })
      end
    end,
  },
}
