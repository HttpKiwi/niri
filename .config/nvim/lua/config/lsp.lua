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
        lua_ls = {
          settings = {
            Lua = {
              runtime = {
                version = "LuaJIT",
              },
              diagnostics = {
                globals = { "vim" },
              },
              workspace = {
                checkThirdParty = false,
                library = {
                  "${3rd}/love2d/library",
                },
              },
              telemetry = {
                enable = false,
              },
            },
          },
        },
      },
    },
  },
}