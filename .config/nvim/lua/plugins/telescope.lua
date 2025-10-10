-- lua/plugins/telescope.lua
return {
  "nvim-telescope/telescope.nvim",
  keys = {
    {
      "<leader>fg",
      function()
        require("telescope.builtin").live_grep()
      end,
      desc = "Grep for string in CWD with rg",
    },
  },
}
