# Gentleman.Dots — Architectural Plan

This document captures the goals, architecture, and working practices for this repository so new sessions can align quickly without repeated context.

## Scope & Goals

- Deliver a clean, reproducible macOS and Linux developer environment using Nix Flakes + Home Manager.
- Prioritize simplicity, stability, and maintainability over breadth of options.
- Keep the surface area focused: Ghostty (terminal) + Zsh (shell) + Neovim (editor) + essential CLI tools.
- Minimize surprises: default behaviors should be sane, with clear opt‑in for extras.

## Platform Targets

- macOS: `x86_64-darwin` and `aarch64-darwin`.
- Linux: `x86_64-linux` and `aarch64-linux`.

## Architecture Overview

- Flake entrypoint: `flake.nix` orchestrates modules.
- Home Manager as the single source of truth for user config.
- Declarative files via `home.file` where appropriate; program modules enabled explicitly.
- Dotfiles live in this repo as regular files (no symlinks into `/nix/store` within the repo). Home Manager creates symlinks in `$HOME` at apply time (expected behavior).

### Modules currently included

- `ghostty.nix` — copies `./ghostty` into `~/.config/ghostty`.
- `zsh.nix` — full `.zshrc` via `programs.zsh.initContent`, with Homebrew path loading for login and non‑login shells.
- `starship.nix` — prompt configuration at `~/.config/starship.toml`.
- `nvim.nix` — copies Neovim config to `~/.config/nvim` and runs Lazy clean/sync on switch when `git` is present.
- `neovide.nix` — installs Neovide on macOS and writes a minimal `~/.config/neovide/config.toml`.
- `television.nix`, `oil-scripts.nix`, `opencode.nix` — utilities and scripts.

### Modules intentionally NOT included

- Alternate terminals (WezTerm), multiplexers (tmux, zellij), and shells (fish, nushell).
- Zed, Gemini, and other optional apps.

## Coding & Style Guidelines

- Nix files
  - 2‑space indentation
  - Use `lib.mkIf` for conditional logic; detect platform with `pkgs.stdenv.isDarwin`.
  - File paths with `./relative/path` syntax.
  - Keep module scopes narrow; avoid cross‑module side effects.

- Lua (Neovim)
  - 2‑space indentation; snake_case for vars/functions.
  - Prefer `require()` over `vim.cmd()`; comment non‑obvious logic.
  - Lazy loading via `lazy.nvim`; stable plugin imports via LazyVim extras.

- Configuration files
  - Use each tool’s native conventions; keep platform‑specific branches explicit.
  - Maintain existing color schemes and UX conventions.

## External Dependencies

- Git: required before running the installer (install via your distro on Linux, CLT/Homebrew on macOS).
- Ghostty is optional (recommended). On macOS it may be installed via Homebrew; on Linux use your distro or Nix. The installer no longer requires Homebrew.

## Installation Model

- Single command installer: `scripts/install.sh`
  - Validates prerequisites (sudo, git).
  - Installs Nix via official script if missing (Linux + macOS).
  - Ensures `/etc/nix/nix.conf` enables `flakes nix-command`.
  - macOS: optionally installs Ghostty via Homebrew when available.
  - Applies Home Manager flake for the detected platform/arch and sets HM Zsh as default shell.

## Future: Custom Install Mode

- Add `--custom` flag (stub present) for interactive selection.
- Selection UI: prefer `gum` or `fzf` with clear, colored choices.
- Parameter passing patterns (TBD):
  - Environment variables read by modules, or
  - `home-manager` `--impure` with env, or
  - Flake `--override-input` / `extraSpecialArgs` for structured options.
  - Keep defaults clean; custom mode only adds opt‑in packages and (optionally) macOS apps.

## Neovim Debugging (Flutter)

- Goals
  - First-class Flutter/Dart debugging via nvim-dap + flutter-tools.
  - Simple defaults that work without a launch.json; attach supported.

- Components
  - nvim-dap with minimal dap-ui (scopes + controls) and nvim-dap-virtual-text.
  - flutter-tools used for run commands; debugger enabled and run via DAP.

- Defaults
  - Launch `${workspaceFolder}/lib/main.dart` and `example/lib/main.dart`.
  - Attach configuration for running apps.
  - Auto-load `.vscode/launch.json` when present.

- UX
  - Minimal UI: left side panel split in half — Variables (scopes) and Controls side-by-side; inline values via virtual text.
  - Inspect values: hover `<leader>dw`, eval `<leader>de`, scopes `<leader>dS`; toggle UI `<leader>du`.
  - Close Neo-tree on debug start to reduce layout conflicts.
  - Theming: DAP UI uses explicit colors for clarity across themes — variables are purple (theme‑matched: Kanagawa Fuji or Catppuccin Mauve); most other text is white; borders follow the theme.

- Notes
  - Requires `dart debug_adapter` resolvable on PATH.
  - Virtual text enabled at EOL; .env merged into session env if present.
  - `flutter-tools` debugger enabled; dev_log window disabled to avoid conflicts.

## Best Practices & Constraints

- Avoid repo symlinks to `/nix/store`; Home Manager manages symlinks in `$HOME`.
- Don’t broaden scope without owner confirmation; be surgical with changes.
- Validate changes with `nix flake check` and a fresh `home-manager switch` where possible.
- Keep docs simple and front‑loaded: installation first, maintenance later.

## Validation Checklist (for releases)

- Fresh macOS (Intel/ARM) with Git present and optionally Homebrew.
- Fresh Linux (Intel/ARM) with Git present.
- Run installer once; ensure:
  - Nix is installed and the profile is sourced in the current shell.
  - `/etc/nix/nix.conf` includes experimental features.
  - Ghostty availability verified or install separately (Homebrew on macOS; distro/Nix on Linux).
  - Home Manager switch succeeds; Zsh set as default shell.
  - New terminal session picks up configuration (PATH, Starship, Neovim). 

## Linux Migration Work Log

- Completed
  - Installer: add Linux support (ARM/x86), nix.conf edits portable, daemon reload best-effort, `nix run home-manager` path, Linux-safe shell switching.
  - Installer: ensure Nix loads via `$HOME/.nix-profile/etc/profile.d/nix.sh` and `$HOME/.nix-profile/bin` added to PATH so `home-manager` is discoverable.
  - Flake: add `x86_64-linux`/`aarch64-linux` targets and homeConfigurations, per-platform Android SDK path, Linux clipboard tools.
  - Neovide: enable on Linux and set XDG config; add Linux copy/paste keybinds using Ctrl+Shift with `unnamedplus`.
  - Ghostty: add Linux-friendly copy/paste keybinds (Ctrl+Shift+C/V).
  - Linux: add `ghostty` to `home.packages` so it’s installed via Nix; after HM switch, source HM session vars and prepend HM bin to PATH in installer so new binaries are usable immediately.

- Next
  - Validate on a fresh Linux VM (Wayland/X11) and confirm clipboard behavior with `xclip` vs `wl-clipboard`.
  - Review zsh init for Linux-only path tweaks and reduce Homebrew logic under Linux.
  - Optional: package Ghostty via Nix on Linux (or distro-specific instructions).
