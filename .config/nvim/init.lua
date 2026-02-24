-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

-- Configure filetypes
vim.filetype.add({
  extension = {
    qml = "qml",
    dart = "dart",
    lua = "lua",
  },
  filename = {
    qmldir = "qml",
    pubspec = "yaml",
    analysis_options = "yaml",
  },
  pattern = {
    ["conf.lua"] = "lua",
  },
})
