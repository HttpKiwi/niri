-- LSP configuration for LazyVim
return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        dartls = {
          settings = {
            dart = {
              analysisExcludedFolders = {},
              enableSnippets = true,
              updateImportsOnRename = true,
              completeFunctionCalls = true,
              showTodos = true,
            },
          },
        },
      },
    },
  },
}