-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

-- Configure filetypes
vim.filetype.add({
  extension = {
    qml = "qml",
    dart = "dart",
  },
  filename = {
    qmldir = "qml",
    pubspec = "yaml",
    analysis_options = "yaml",
  },
})
