# Neovim configuration

Neovim config for daily driver

This repository contains my personal Neovim configuration, including all my key mappings, plugins, and settings. It is designed to provide a powerful and efficient development environment with a focus on productivity, modern features, and smooth editing experience.

## Configuration Highlights
### Core Settings (config/)

autocmds.lua – Defines custom auto commands for events such as opening files or switching buffers.

floaterminal.lua – Configures floating terminal windows inside Neovim.

jdtls.lua – Setup for Java LSP (Language Server Protocol) using jdtls for intelligent code navigation and completion.

keymaps.lua – Custom key bindings to streamline workflow and improve efficiency.

options.lua – General Neovim options like line numbers, tab size, search behavior, and more.

### Plugins (plugins/)

autopairs.lua – Automatically closes brackets, quotes, and parentheses.

cmp.lua – Setup for nvim-cmp completion plugin with snippet support.

colorscheme.lua – Defines the preferred colorscheme and highlights.

comment.lua – Plugin to comment/uncomment lines or blocks quickly.

git.lua – Integration with Git for inline diff, blame, and commands.

harpoon.lua – Navigation between frequently used files with Harpoon.

lsp-config.lua – Core LSP setup for multiple languages with diagnostics, code actions, and formatting.

lualine.lua – Status line configuration for a modern, informative interface.

none-ls.lua – Setup for null-ls to integrate formatters and linters.

nvim-dap.lua – Debugging setup using DAP (Debug Adapter Protocol).

nvim-tree.lua – File explorer with tree view, icons, and navigation features.

springboot-nvim.lua – Support for Spring Boot development.

telescope.lua – Fuzzy file finder, live grep, and other productivity features.

treesitter.lua – Advanced syntax highlighting, parsing, and code folding.

whichkey.lua – Shows available key bindings in a popup, improving discoverability.

### Features

Fully modular: Config separated into core and plugin configurations for easier maintenance.

LSP-ready: Supports multiple languages with nvim-lspconfig.

File navigation & search: With telescope and nvim-tree.

Debugging & development: Using nvim-dap and language-specific tools.

Productivity boosts: Key mappings, Harpoon, autopairs, commenting tools.

## Installation

1. Clone this repository 
```bash
git clone https://github.com/superunyx/nvim-config.git ~/.config/nvim
```

2. Open Neovim and install plugins
```vim
:PackerSync
```

## Contributing

This is a personal configuration, but feel free to open issues or pull requests if you have improvements or bug fixes.


