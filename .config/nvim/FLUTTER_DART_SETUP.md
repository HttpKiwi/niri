# Flutter and Dart Configuration for Neovim

This configuration provides comprehensive Flutter and Dart development support for Neovim using LazyVim.

## Features

### Flutter Tools
- **Flutter Run**: Start Flutter applications
- **Hot Reload**: Hot reload changes during development
- **Hot Restart**: Restart the Flutter application
- **Flutter Outline**: View widget tree structure
- **Flutter Log**: View Flutter logs
- **Device Selection**: Choose target device for running apps
- **Debugging**: Integrated debugging with DAP

### Dart Language Support
- **Language Server**: Full Dart language server support
- **Syntax Highlighting**: Dart syntax highlighting
- **Code Completion**: Intelligent code completion
- **Error Detection**: Real-time error and warning detection
- **Code Actions**: Quick fixes and refactoring
- **Go to Definition**: Navigate to symbol definitions
- **References**: Find all references to symbols
- **Rename**: Rename symbols across the project

### Formatting and Linting
- **Auto Formatting**: Automatic Dart code formatting
- **Linting**: Dart analysis and linting
- **Code Style**: Consistent code style enforcement

## Key Mappings

### Flutter Commands
- `<leader>Fr` - Flutter Run
- `<leader>Fq` - Flutter Quit
- `<leader>Fh` - Flutter Hot Reload
- `<leader>Fd` - Flutter Hot Restart
- `<leader>Fp` - Flutter Pub Get
- `<leader>Fo` - Flutter Outline
- `<leader>Fc` - Flutter Copy Profiler URL
- `<leader>Fl` - Flutter Log Clear

### Dart Commands
- `<leader>cd` - Format Dart file
- `<leader>cD` - Analyze Dart file

### LSP Commands
- `gD` - Go to declaration
- `gd` - Go to definition
- `K` - Hover information
- `gi` - Go to implementation
- `<C-k>` - Signature help
- `<leader>rn` - Rename symbol
- `<leader>ca` - Code actions
- `gr` - References
- `<leader>f` - Format code

## File Types

The configuration automatically recognizes:
- `.dart` files as Dart
- `pubspec.yaml` as YAML (Flutter project configuration)
- `analysis_options.yaml` as YAML (Dart analysis configuration)

## Prerequisites

- Flutter SDK installed (detected at `/opt/flutter/`)
- Dart SDK (included with Flutter)
- Neovim with LazyVim

## Installation

The configuration is automatically loaded when you open Neovim. The plugins will be installed automatically via LazyVim.

## Usage

1. Open a Flutter project directory in Neovim
2. Use `<leader>Fr` to run the Flutter app
3. Make changes to your Dart code
4. Use `<leader>Fh` for hot reload or `<leader>Fd` for hot restart
5. Use `<leader>Fo` to view the Flutter widget outline

## Debugging

The configuration includes DAP (Debug Adapter Protocol) support for debugging Flutter applications. You can set breakpoints and debug your Flutter apps directly in Neovim.

## Troubleshooting

If you encounter issues:
1. Make sure Flutter is properly installed and in your PATH
2. Run `:checkhealth` in Neovim to check plugin status
3. Ensure the Dart language server is running (check `:LspInfo`)
4. Verify Flutter tools are working with `:FlutterDevices`

## Configuration Files

- `lua/plugins/flutter.lua` - Flutter tools configuration and keymaps
- `lua/plugins/dart.lua` - Dart language support and snippets
- `lua/plugins/conform.lua` - Dart code formatting configuration
- `lua/config/lsp.lua` - Dart language server configuration
- `init.lua` - Main configuration with file type detection

## Troubleshooting

If you encounter issues:
1. Make sure Flutter is properly installed and in your PATH
2. Run `:checkhealth` in Neovim to check plugin status
3. Ensure the Dart language server is running (check `:LspInfo`)
4. Verify Flutter tools are working with `:FlutterDevices`
5. If you get module errors, restart Neovim to reload the configuration

