# Gentleman.Dots — Architectural Plan

This document captures the goals, architecture, and working practices for this repository so new sessions can align quickly without repeated context.

## Scope & Goals

- Deliver a clean, reproducible macOS developer environment using Nix Flakes + Home Manager.
- Prioritize simplicity, stability, and maintainability over breadth of options.
- Keep the surface area focused: Ghostty (terminal) + Zsh (shell) + Neovim (editor) + essential CLI tools.
- Minimize surprises: default behaviors should be sane, with clear opt‑in for extras.

## Platform Targets

- macOS only: `x86_64-darwin` and `aarch64-darwin`.
- Linux and other platforms are out of scope unless explicitly reintroduced later.

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

- Git: required before running the installer (CLT or Homebrew Git).
- Homebrew or Ghostty: installer requires one of these present (either brew to install Ghostty, or Ghostty already installed).

## Installation Model

- Single command installer: `scripts/install.sh`
  - Validates prerequisites (sudo, git, brew or ghostty).
  - Installs Nix via official script if missing.
  - Ensures `/etc/nix/nix.conf` enables `flakes nix-command`.
  - Optionally installs Ghostty via Homebrew (if brew available).
  - Applies Home Manager flake `.#gentleman` and sets HM Zsh as default shell.

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
  - nvim-dap, nvim-dap-ui (with nvim-nio), nvim-dap-virtual-text.
  - flutter-tools configured with `run_via_dap = true`.

- Defaults
  - Launch `${workspaceFolder}/lib/main.dart` and `example/lib/main.dart`.
  - Attach configuration for running apps.
  - Auto-load `.vscode/launch.json` when present.

- UX
  - UI auto-opens on session start; toggle with `<leader>du`.
  - Inspect values: hover `<leader>dw`, eval `<leader>de`, scopes `<leader>dS`.

- Notes
  - Requires `dart debug_adapter` resolvable on PATH.
  - Virtual text enabled at EOL; .env merged into session env if present.

## Best Practices & Constraints

- Avoid repo symlinks to `/nix/store`; Home Manager manages symlinks in `$HOME`.
- Don’t broaden scope without owner confirmation; be surgical with changes.
- Validate changes with `nix flake check` and a fresh `home-manager switch` where possible.
- Keep docs simple and front‑loaded: installation first, maintenance later.

## Validation Checklist (for releases)

- Fresh macOS (Intel/ARM) with Git + Homebrew or Ghostty present.
- Run installer once; ensure:
  - Nix is installed and daemon profile sourced.
  - `/etc/nix/nix.conf` includes experimental features.
  - Ghostty installed (via brew) or preinstalled.
  - `home-manager switch` succeeds; Zsh set as default.
  - New terminal session picks up configuration (PATH, Starship, Neovim).
