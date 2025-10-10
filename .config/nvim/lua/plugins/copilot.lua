return {
  -- GitHub Copilot
  {
    "github/copilot.vim",
    event = "InsertEnter",
    config = function()
      -- Enable Copilot for all file types
      vim.g.copilot_filetypes = {
        ["*"] = true,
      }
      
      -- Disable Copilot for specific file types if needed
      vim.g.copilot_filetypes = {
        ["*"] = true,
        ["TelescopePrompt"] = false,
        ["DressingInput"] = false,
        ["neo-tree"] = false,
      }
      
      -- Set tab to accept suggestions
      vim.g.copilot_no_tab_map = true
    end,
  },
}