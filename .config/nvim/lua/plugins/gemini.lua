return {
  "marcinjahn/gemini-cli.nvim",
  dependencies = {
    "folke/snacks.nvim",
  },
  keys = {
    { "<leader>ga", "<cmd>Gemini add_file<cr>", desc = "Gemini add file" },
    { "<leader>gd", "<cmd>Gemini diagnostics<cr>", desc = "Gemini diagnostics" },
    { "<leader>gc", "<cmd>Gemini command<cr>", desc = "Gemini command" },
    { "<leader>gt", "<cmd>Gemini toggle<cr>", desc = "Gemini toggle" },
    { "<leader>gq", "<cmd>Gemini ask<cr>", desc = "Gemini ask" },
  },
  config = function()
    require("gemini_cli").setup({
      args = { "--checkpointing" },
    })
  end,
}
