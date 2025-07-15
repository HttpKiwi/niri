-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- QML specific keymaps
vim.api.nvim_create_autocmd("FileType", {
  pattern = "qml",
  callback = function(event)
    local opts = { buffer = event.buf }
    vim.keymap.set("n", "<leader>cq", function()
      vim.lsp.buf.code_action()
    end, vim.tbl_extend("force", opts, { desc = "QML Code Action" }))

    vim.keymap.set("n", "<leader>cr", function()
      vim.lsp.buf.rename()
    end, vim.tbl_extend("force", opts, { desc = "QML Rename" }))

    vim.keymap.set("n", "<leader>cf", function()
      require("conform").format({ bufnr = event.buf })
    end, vim.tbl_extend("force", opts, { desc = "QML Format" }))

    vim.keymap.set("n", "<leader>cl", function()
      require("lint").try_lint()
    end, vim.tbl_extend("force", opts, { desc = "QML Lint" }))
  end,
})

-- QML diagnostic command
vim.api.nvim_create_user_command("QMLDiagnostic", function()
  local buf = vim.api.nvim_get_current_buf()
  local ft = vim.bo[buf].filetype

  print("Current filetype: " .. ft)
  print("QML LSP Status:")

  local clients = vim.lsp.get_active_clients({ bufnr = buf })
  if #clients == 0 then
    print("  No LSP clients attached")
    -- Check if qmlls is available
    local qmlls_path = vim.fn.exepath("qmlls")
    if qmlls_path == "" then
      print("  qmlls not found in PATH")
    else
      print("  qmlls found at: " .. qmlls_path)
    end
  else
    for _, client in ipairs(clients) do
      print("  Client: " .. client.name .. " (ID: " .. client.id .. ")")
      print("  Root dir: " .. (client.config.root_dir or "unknown"))
    end
  end
end, { desc = "Show QML LSP diagnostic information" })
