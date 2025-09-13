# Gentleman.Dots

<img width="2998" height="1649" alt="image" src="https://github.com/user-attachments/assets/0ef4e8fb-e08c-4554-9028-43c36c79acde" />

---

## Description

This repository provides a complete, declarative development environment configuration using Nix Flakes and Home Manager. Everything is configured through local modules and automatically installs all dependencies.

### 🛠️ Development Tools & Languages

- **Languages**: Node.js, Bun, Cargo/Rust, Go, GCC
- **Package Managers**: Volta (Node.js), Cargo, Bun
- **Build Tools**: Nil (Nix LSP), Nixd (Nix language server)
- **Utilities**: jq, bash, fd, ripgrep, coreutils, unzip, bat, yazi

### 🐚 Shell Configuration

- **Zsh**: Primary shell with modern enhancements
- **Starship**: Prompt configured for Zsh

### 🖥️ Terminal

- **Ghostty**: GPU-accelerated terminal with custom theme and keybinds

### ⚡ Development Environment

- **Neovim**: Fully configured IDE with LazyVim, AI assistants, and 40+ plugins
- **Git & GitHub CLI**: Pre-configured version control
- **Lazy Git**: Terminal UI for Git operations

### 🤖 AI Integrations

- **Copilot + CopilotChat**: Inline ghost suggestions and chat
- **OpenCode**: AI assistant integration
- **Multiple AI providers**: Support for various AI coding assistants

### 🔧 System Utilities

- **Television**: Modern file navigator and system monitor
- **Zoxide**: Smart directory jumping
- **Atuin**: Enhanced shell history
- **Carapace**: Universal shell completions
- **FZF**: Fuzzy finder integration
 

### 📝 Development Workflow

- **Oil.nvim**: Custom file navigation scripts
- **Custom Scripts**: Productivity-enhancing shell scripts
- **Nerd Fonts**: Iosevka Term for consistent typography
- **Declarative Configuration**: Everything version-controlled and reproducible

The flake automatically handles system-specific configurations, installs all dependencies, and sets up your complete development environment with a single command.

---

## Features Overview

### 🎯 What You Get

- **Zero Configuration**: Everything works out of the box
- **Declarative**: Version-controlled, reproducible environment
- **Modern Toolchain**: Latest development tools and utilities
- **AI-Enhanced**: Multiple AI coding assistants integrated
- **Zsh-Only Shell**: Single, focused Zsh configuration
- **Ghostty Terminal**: Streamlined terminal setup
- **macOS Optimized**: Specifically tuned for macOS workflows

### 🔧 Technical Stack

| Category            | Tools                                                    |
| ------------------- | -------------------------------------------------------- |
| **Package Manager** | Nix with Flakes + Home Manager                           |
| **Shell**           | Zsh with Starship prompt                                  |
| **Terminal**        | Ghostty                                                   |
| **Editor**          | Neovim (LazyVim)                                         |
| **Languages**       | Node.js, Rust, Go, with Volta management                 |
| **AI Tools**        | Copilot/CopilotChat, OpenCode, multiple providers        |
| **Navigation**      | Television, Yazi, Oil.nvim, Zoxide                       |
| **Development**     | Git, GitHub CLI, Lazy Git                                |

### 📁 Project Structure

```
.
├── flake.nix              # Main Nix flake configuration
├── README.md              # This file
├── zsh.nix                # Zsh configuration
├── starship.nix           # Starship prompt configuration
├── nvim.nix               # Neovim configuration
├── ghostty.nix            # Ghostty terminal configuration
├── opencode.nix           # OpenCode AI configuration
├── television.nix         # Television file navigator
├── oil-scripts.nix        # Custom Oil.nvim scripts
├── nvim/                  # Neovim plugins and settings
├── ghostty/               # Ghostty themes and config
├── 
├── scripts/               # Custom utility scripts
└── scripts/               # Custom utility scripts
```

## Installation Steps (for macOS)

### 0. Prerequisites

- Install Git first (required for plugin bootstrap):
  - Xcode Command Line Tools: `xcode-select --install`
  - or Homebrew: `brew install git`
  - Ensure `git --version` works in your terminal before proceeding.

### 1. Install the Nix Package Manager

```bash
sh <(curl -L https://nixos.org/nix/install)
```

### 2. Configure Nix to Use Extra Experimental Features

To enable the experimental features for flakes and the new `nix-command` (needed for our declarative setup), create/edit the configuration file:

```bash
# For daemon installation (default on macOS)
# The file may not exist, create it if needed
sudo mkdir -p /etc/nix
sudo nano /etc/nix/nix.conf
# Or: sudo vi /etc/nix/nix.conf
```

Add:

```
extra-experimental-features = flakes nix-command
build-users-group = nixbld
```

_(This is necessary because support for flakes and the new Nix command is still experimental, but it allows us to have a fully declarative and reproducible configuration.)_

### 3. Prepare Your System

**No need to edit `flake.nix` for system configuration!** The flake supports both Intel and Apple Silicon Macs.

You only need to update your username in `flake.nix`:

- Change `home.username = "YourUser";` to your actual username
- The home directory is automatically set to `/Users/YourUser`

### 4. Install Terminal (Ghostty)

This flake configures Ghostty. Install it from:

- Ghostty: https://ghostty.org/download
  - Reload config with Shift + Cmd + ,
  - GPU-accelerated with custom theme and keybinds

 

### 6. Install Home Manager

Before running the flake configuration, you need to set up Home Manager:

```bash
# Add home-manager channel
nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager

# Update channels
nix-channel --update

# Install home-manager
nix-shell '<home-manager>' -A install
```

### 7. Run the Installation

Once you have cloned the repository and are **inside its directory**, run the command for your system.

**⚠️ Important:** You must be in the root of this project directory for the command to work, as it uses `.` to find the `flake.nix` file.

**For any Mac (the flake auto-detects your system):**

```bash
home-manager switch --flake .#gentleman
```

**Alternative: Specific system configurations:**

- **Apple Silicon Macs (M1/M2/M3/M4)**:

  ```bash
  home-manager switch --flake .#gentleman-macos-arm
  ```

- **Intel Macs**:

  ```bash
  home-manager switch --flake .#gentleman-macos-intel
  ```

_(These commands apply the configuration defined in the flake, installing all dependencies and applying the necessary settings.)_

### 8. Verify Installation

**PATH is configured automatically on macOS!**

### 9. Default Shell (Zsh)

```bash
shellPath="$HOME/.local/state/nix/profiles/home-manager/home-path/bin/zsh" && sudo sh -c "grep -Fxq '$shellPath' /etc/shells || echo '$shellPath' >> /etc/shells" && sudo chsh -s "$shellPath" "$USER"
```

---

## Configuration Details

### 🔧 How It Works

- **Declarative Setup**: All configurations are defined in Nix modules
- **Automatic Deployment**: Files are copied to correct macOS locations
- **Dependency Management**: All tools and dependencies installed automatically
- **Version Pinning**: Reproducible builds with locked versions
- **System Integration**: Proper PATH configuration and shell integration

### 📍 File Locations

Configurations are automatically deployed to:

| Tool           | Location                                 |
| -------------- | ---------------------------------------- |
| **Ghostty**    | `~/.config/ghostty/`                     |
| **Neovim**     | `~/.config/nvim/`                        |
| **Starship**   | `~/.config/starship.toml`                |
| **Television** | `~/.config/television/`                  |

### 🚀 Performance Features

- **Shell Completions**: Carapace-powered Zsh completions
- **Smart History**: Atuin for enhanced command history across shells
- **Fuzzy Finding**: FZF integration for quick file/command finding
- **Directory Navigation**: Zoxide for intelligent directory jumping
- **File Management**: Yazi and Television for modern file browsing
- **Git Workflow**: Lazy Git for streamlined version control

### 🤖 AI Development Features

- **GitHub Copilot**: Inline ghost suggestions (no intrusive popup)
- **CopilotChat**: Chat-based assistance inside Neovim
- **Multiple AI Providers**: Support for various AI services
- **Productivity Focused**: AI assistants configured for maximum productivity

### 🎨 Theming & Customization

- **Consistent Themes**: Catppuccin and custom themes across all tools
- **Nerd Font Support**: Iosevka Term for perfect icon rendering
- **GPU Acceleration**: Modern terminals with hardware acceleration
- **Custom Key Bindings**: Vim-like navigation across all tools

## Troubleshooting

### Common Issues

**Command not found after installation:**

```bash
hash -r  # Refresh command cache
source ~/.zshrc  # or ~/.bashrc
```

**Nix installation issues:**

- Ensure `/etc/nix/nix.conf` has experimental features enabled
- Restart terminal after Nix installation
- Check that you're in the project directory when running commands

**Terminal not picking up themes:**

---

## Maintenance

### Keep dependencies up to date

- Nix inputs (flake.lock):
  - This repo runs a best‑effort `nix flake update` on every `home-manager switch` to refresh inputs.
  - You can update manually too:
    - `cd ~/Gentleman.Dots && nix flake update && home-manager switch --flake .#gentleman`
  - Tip: commit `flake.lock` after updates to pin versions.

- Neovim plugins (lazy.nvim):
  - On every switch we run `nvim --headless "+Lazy! sync" +qa` to install/update plugins.
  - Manual update:
    - Inside Neovim: `:Lazy sync`
    - Headless: `nvim --headless "+Lazy! sync" +qa`

### Disable auto‑updates (optional)

- Disable flake auto‑update: comment/remove `home.activation.updateFlakeInputs` in `flake.nix`.
- Disable Neovim auto‑update: comment/remove `home.activation.nvimLazySync` in `nvim.nix`.

### Recommended update flow

1. `cd ~/Gentleman.Dots`
2. `home-manager switch --flake .#gentleman`
3. Review changes, then commit `flake.lock` if updates look good.

## Sessions (auto-save/restore per directory)

- Neovim saves a session on exit and restores it when you start `nvim` in the same directory (with no file args).
- This restores windows, tabs, layout (e.g., Neo-tree panes), and more.

Shortcuts:
- `<leader>qs` — Save session now
- `<leader>ql` — Load session for current directory
- `<leader>qd` — Stop session (don’t save on exit)

Notes:
- Auto-restore triggers only when starting `nvim` without explicit files (`nvim` vs `nvim file.lua`).
- Sessions are stored under `:echo stdpath('state') .. '/sessions'`.
- Terminal job buffers are not restored by Vim sessions; reopen terminals if needed.

- For Ghostty: Use **Shift + Cmd + ,** to reload config
- Verify config files are in correct locations

### Customization

**Adding your own configurations:**

1. Edit the relevant `.nix` files
2. Run the installation command again
3. Changes are applied automatically

**Managing versions:**

- Update `flake.lock` with: `nix flake update`
- Pin specific package versions in the flake

 

## AI Configuration for Neovim

This configuration includes support for the following AI tools:

- **Avante.nvim** - AI‑powered coding assistant
- **CopilotChat.nvim** - GitHub Copilot chat interface
- **OpenCode.nvim** - OpenCode AI integration
- **CodeCompanion.nvim** - Multi‑AI provider support

### Copilot setup (inline ghost text)

- Copilot suggestions show inline as ghost text (like VS Code), not in the completion popup.
- Keymaps:
  - Accept: Ctrl+Right
  - Accept word: Alt+Right
  - Accept line: Alt+L
  - Next/Prev: Alt+] / Alt+]
  - Dismiss: Ctrl+]

### Switching AI tools

- Use one assistant at a time to avoid conflicts.
- Enable/disable plugins under `nvim/lua/plugins/` as needed.
- Restart Neovim after changes.

## Contributing

Contributions welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Test your changes thoroughly
4. Submit a pull request

For questions or issues, open a GitHub issue.

---

**Happy coding!** 🚀

— Gentleman Programming
