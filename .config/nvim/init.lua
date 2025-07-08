-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

-- Configure QML filetype
vim.filetype.add({
  extension = {
    qml = "qml",
  },
  filename = {
    qmldir = "qml",
  },
})
