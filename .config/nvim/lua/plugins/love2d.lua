return {
  {
    "S1M0N38/love2d.nvim",
    event = "VeryLazy",
    ft = { "lua" },
    opts = {},
    keys = {
      {
        "<leader>vv",
        "<cmd>LoveRun<cr>",
        desc = "Run LÖVE game",
      },
      {
        "<leader>vq",
        "<cmd>LoveQuit<cr>",
        desc = "Quit LÖVE game",
      },
      {
        "<leader>vr",
        "<cmd>LoveRestart<cr>",
        desc = "Restart LÖVE game",
      },
    },
  },
}
