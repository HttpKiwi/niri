-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- QML filetype autocmd
vim.api.nvim_create_autocmd({"BufRead", "BufNewFile"}, {
  pattern = "*.qml",
  callback = function()
    vim.bo.filetype = "qml"
  end,
})

-- QML LSP debugging autocmd
vim.api.nvim_create_autocmd("FileType", {
  pattern = "qml",
  callback = function(event)
    local clients = vim.lsp.get_active_clients({ bufnr = event.buf })
    if #clients == 0 then
      vim.notify("No LSP clients attached to QML buffer", vim.log.levels.WARN)
    else
      for _, client in ipairs(clients) do
        vim.notify("LSP client '" .. client.name .. "' attached to QML buffer", vim.log.levels.INFO)
      end
    end
  end,
})

-- QML auto-linting
vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
  pattern = "*.qml",
  callback = function()
    require("lint").try_lint()
  end,
})
