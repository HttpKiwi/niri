return {
  -- Flutter and Dart development plugins
  {
    "dart-lang/dart-vim-plugin",
    event = "VeryLazy",
  },
  {
    "akinsho/flutter-tools.nvim",
    ft = { "dart" },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "stevearc/dressing.nvim", -- optional for vim.ui.select
    },
    config = function()
      require("flutter-tools").setup({
        decorations = {
          statusline = {
            -- set to true to be able use the 'flutter_tools_decorations.app_version' in your statusline
            -- this will show the current version of the flutter app from the pubspec.yaml file
            app_version = true,
            -- set to true to be able use the 'flutter_tools_decorations.device' in your statusline
            -- this will show the currently selected device
            device = true,
            -- set to true to be able use the 'flutter_tools_decorations.project_config' in your statusline
            -- this will show the currently selected project configuration
            project_config = true,
          },
        },
        debugger = { -- integrate with nvim dap + install dart code debugger
          enabled = true,
          run_via_dap = true, -- use dap instead of a plenary job
          register_configurations = function(paths)
            require("dap").configurations.dart = {
              {
                type = "dart",
                request = "launch",
                name = "Launch Flutter App",
                dartSdkPath = "/opt/flutter/bin/cache/dart-sdk/",
                flutterSdkPath = "/opt/flutter/",
                program = "${workspaceFolder}/lib/main.dart",
                cwd = "${workspaceFolder}",
              },
              {
                type = "dart",
                request = "launch",
                name = "Launch Flutter App (Profile mode)",
                dartSdkPath = "/opt/flutter/bin/cache/dart-sdk/",
                flutterSdkPath = "/opt/flutter/",
                program = "${workspaceFolder}/lib/main.dart",
                cwd = "${workspaceFolder}",
                flutterMode = "profile",
              },
              {
                type = "dart",
                request = "launch",
                name = "Launch Flutter App (Release mode)",
                dartSdkPath = "/opt/flutter/bin/cache/dart-sdk/",
                flutterSdkPath = "/opt/flutter/",
                program = "${workspaceFolder}/lib/main.dart",
                cwd = "${workspaceFolder}",
                flutterMode = "release",
              },
            }
          end,
        },
        fvm = false, -- takes longer to set up if enabled
        widget_guides = {
          enabled = true,
        },
        closing_tags = {
          highlight = "ErrorMsg", -- highlight for the closing tag
          prefix = ">", -- character to use for close tag e.g. > Widget
          enabled = true -- set to false to disable
        },
        dev_log = {
          enabled = true,
          notify_errors = false, -- if there is an error whilst running then notify the user
          open_cmd = "tabedit", -- command to use to open the dev log buffer
        },
        dev_tools = {
          autostart = false, -- autostart devtools server if not detected
          auto_open_browser = false, -- Automatically opens devtools in the browser
        },
        outline = {
          open_cmd = "30vnew", -- command to use to open the outline buffer
          auto_open = false -- if true this will open the outline automatically when it is first populated
        },
        lsp = {
          color = { -- show the derived colours for dart variables
            enabled = true, -- whether or not to highlight color variables at all, only supported on flutter >= 2.10
            background = false, -- highlight the background
            foreground = false, -- highlight the foreground
            virtual_text = true, -- show the highlight using virtual text
            virtual_text_str = "■", -- the virtual text character to highlight
          },
          -- on_attach = function(client, bufnr)
          --   require("flutter-tools").lsp.on_attach(client, bufnr)
          -- end,
          -- capabilities = my_custom_capabilities, -- e.g. lsp_status capabilities
          -- --- OR you can specify a function to deactivate or change or control how the config is created
          -- capabilities = function(config)
          --   config.specificThing = false
          --   return config
          -- end,
          -- see the link below for details on each option:
          -- https://github.com/dart-lang/sdk/blob/master/pkg/analysis_server/tool/lsp_spec/README.md#client-workspace-configuration
          settings = {
            showTodos = true,
            completeFunctionCalls = true,
            analysisExcludedFolders = {},
            renameFilesWithClasses = "prompt", -- "always"
            enableSnippets = true,
            updateImportsOnRename = true, -- Whether to update imports and other directives when files are renamed
          },
        },
      })
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = { "dart" },
    },
  },
  -- Flutter keymaps
  {
    "LazyVim/LazyVim",
    opts = {
      keys = {
        {
          "<leader>Fl",
          ":FlutterLogClear<CR>",
          desc = "Flutter log clear",
        },
        {
          "<leader>Fr",
          ":FlutterRun<CR>",
          desc = "Flutter run",
        },
        {
          "<leader>Fq",
          ":FlutterQuit<CR>",
          desc = "Flutter quit",
        },
        {
          "<leader>Fh",
          ":FlutterHotReload<CR>",
          desc = "Flutter hot reload",
        },
        {
          "<leader>Fd",
          ":FlutterHotRestart<CR>",
          desc = "Flutter hot restart",
        },
        {
          "<leader>Fp",
          ":FlutterPubGet<CR>",
          desc = "Flutter pub get",
        },
        {
          "<leader>Fo",
          ":FlutterOutline<CR>",
          desc = "Flutter outline",
        },
        {
          "<leader>Fc",
          ":FlutterCopyProfilerUrl<CR>",
          desc = "Flutter copy profiler URL",
        },
      },
    },
  },
}

