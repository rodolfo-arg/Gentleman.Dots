# Flutter Plugin Debugging (Neovim)

This setup enables debugging Flutter apps (including plugin example apps) using Neovim’s nvim-dap and flutter-tools.

## Prerequisites

- Flutter and Dart available on PATH (`flutter`, `dart`).
- A device or emulator is running (`flutter devices`).
- Open Neovim in the project root of your plugin/app.

## What’s Configured

- Dart DAP adapter (`dart debug_adapter`) is auto-detected.
- flutter-tools debugger is enabled and runs via nvim-dap.
- nvim-dap reads `.vscode/launch.json` if present and maps entries with `"type": "dart"`.
- Default nvim-dap entries are provided if no `launch.json` exists:
  - Launch `lib/main.dart` in the current workspace
  - Launch `example/lib/main.dart` for typical plugin repos
  - Attach to a running Dart/Flutter process

- nvim-dap-ui auto-opens on session start; close/toggle with `<leader>du`.
- nvim-dap-virtual-text shows inline values at EOL during stops.

## Recommended .vscode/launch.json

Place this in your project if you need multiple profiles or custom args. nvim-dap will pick it up automatically.

```
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Flutter: Launch app",
      "request": "launch",
      "type": "dart",
      "program": "${workspaceFolder}/lib/main.dart",
      "cwd": "${workspaceFolder}"
    },
    {
      "name": "Flutter: Launch example (plugin)",
      "request": "launch",
      "type": "dart",
      "program": "${workspaceFolder}/example/lib/main.dart",
      "cwd": "${workspaceFolder}/example"
    },
    {
      "name": "Flutter: Attach",
      "request": "attach",
      "type": "dart",
      "cwd": "${workspaceFolder}",
      "toolArgs": ["--device-id", "chrome"],
      "program": null
    }
  ]
}
```

Notes:
- Use `toolArgs` to target a specific device (e.g., `--device-id <id>`). Omit for auto-pick.
- For plugin repos, the example app typically lives under `example/`.

## Basic Workflow

- Select a device: run `flutter devices` in a terminal or use your emulator.
- In Neovim:
  - Set a breakpoint: `<leader>db`
  - Start/continue: `<leader>dc`
  - Step over/out/into: `<leader>dO` / `<leader>do` / `<leader>di`
  - Stop: `<leader>dt`

If `.vscode/launch.json` exists, it’s auto-loaded when present. Otherwise, press `<leader>dc` to use the sane defaults above.

## Inspecting Variables

- Open/close the debug UI: `<leader>du` (auto-opens on start)
- Hover variable under cursor: `<leader>dw`
- Evaluate expression (prompt, opens in sidebar): `<leader>de`
- Evaluate visual selection: select text, then `<leader>de`
- Scopes (floating window): `<leader>dS`

Notes:
- Inline values appear at end-of-line via virtual text. Full details and children render in the Scopes panel or hover.


## Troubleshooting

- No debug start: ensure `dart` is on PATH and `dart debug_adapter` works.
- No device: start a simulator or connect a device.
- launch.json ignored: ensure its `type` is `"dart"`.
