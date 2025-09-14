<div align="center"># Neovim configuration</div>

Neovim config for daily driver

This repository contains my personal Neovim configuration, including all my key mappings, plugins, and settings. It is designed to provide a powerful and efficient development environment with a focus on productivity, modern features, and smooth editing experience.

## Configuration Highlights
### Core Settings (config/)

1. Autocmds – Defines custom auto commands for events such as opening files or switching buffers.

2. Floaterminal – Configures floating terminal windows inside Neovim.

3. jdtls – Setup for Java LSP (Language Server Protocol) using jdtls for intelligent code navigation and completion.

4. Keymaps – Custom key bindings to streamline workflow and improve efficiency.

5. Options – General Neovim options like line numbers, tab size, search behavior, and more.

### Plugins (plugins/)

1. Autopairs – Automatically closes brackets, quotes, and parentheses.

2. cmp – Setup for nvim-cmp completion plugin with snippet support.

3. Colorscheme – Defines the preferred colorscheme and highlights.

4. Comment – Plugin to comment/uncomment lines or blocks quickly.

5. Git – Integration with Git for inline diff, blame, and commands.

6. Harpoon – Navigation between frequently used files with Harpoon.

7. lsp-config – Core LSP setup for multiple languages with diagnostics, code actions, and formatting.

8. Lualine – Status line configuration for a modern, informative interface.

9. none-ls – Setup for null-ls to integrate formatters and linters.

10. nvim-dap – Debugging setup using DAP (Debug Adapter Protocol).

11. nvim-tree – File explorer with tree view, icons, and navigation features.

12. Springboot-nvim – Support for Spring Boot development.

13. Telescope – Fuzzy file finder, live grep, and other productivity features.

14. Treesitter – Advanced syntax highlighting, parsing, and code folding.

15. Whichkey – Shows available key bindings in a popup, improving discoverability.

### Features

* Fully modular: Config separated into core and plugin configurations for easier maintenance.

* LSP-ready: Supports multiple languages with nvim-lspconfig.

* File navigation & search: With telescope and nvim-tree.

* Debugging & development: Using nvim-dap and language-specific tools.

* Productivity boosts: Key mappings, Harpoon, autopairs, commenting tools.


## Installation

### 1. Inital Setup

Make sure you have [Neovim](https://github.com/neovim/neovim) and [Git](https://git-scm.com/) installed for your operating system.

### 2. Create Neovim config folder

For Windows:<br><br>
Create a Neovim config folder name 'nvim' like this:
```makefile
C:\Users\<user>\AppData\Local\nvim
```
For linux:<br> 
```bash
mkdir ~/.config/nvim
```

### 3. Clone this repository to your Neovim folder

For Windows: 
```bash
git clone https://github.com/superunyx/nvim-config.git C:\Users\<user>\AppData\Local\nvim
```

For linux:
```bash
git clone https://github.com/superunyx/nvim-config.git ~/.config/nvim
```

### 4. Open Neovim and install plugins
```vim
:Lazy
```

### 5. Update any plugins inside Lazyvim

Once inside the Lazy menu simple press "Shift+U" to update all the plugins.

## Contributing

This is a personal configuration, but feel free to open issues or pull requests if you have improvements or bug fixes.


