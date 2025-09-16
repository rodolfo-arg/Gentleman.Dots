{ pkgs, lib, unstablePkgs ? null, ... }:
let
  # Prefer unstablePkgs when provided; fallback to pkgs
  pkgSet = if unstablePkgs == null then pkgs else unstablePkgs;
  # macOS-only wrapper that hides the terminal while Neovide runs
  neovideWrapper = pkgs.writeShellApplication {
    name = "neovide";
    runtimeInputs = [ pkgSet.neovide ];
    text = ''
      set -euo pipefail

      term_prog="''${TERM_PROGRAM:-}"
      term_app=""
      case "''${term_prog}" in
        Ghostty) term_app="Ghostty" ;;
        "iTerm.app") term_app="iTerm" ;;
        Apple_Terminal) term_app="Terminal" ;;
        WezTerm) term_app="WezTerm" ;;
        kitty) term_app="kitty" ;;
        Alacritty) term_app="Alacritty" ;;
        *) term_app="" ;;
      esac

      hide_terminal() {
        if [ -n "''${term_app}" ]; then
          /usr/bin/osascript -e "tell application \"''${term_app}\" to hide" >/dev/null 2>&1 || true
        else
          # Fallback: hide the frontmost app (may require Accessibility permission)
          /usr/bin/osascript -e 'tell application "System Events" to keystroke "h" using command down' >/dev/null 2>&1 || true
        fi
      }

      show_terminal() {
        if [ -n "''${term_app}" ]; then
          /usr/bin/osascript -e "tell application \"''${term_app}\" to activate" >/dev/null 2>&1 || true
        fi
      }

      # Hide terminal, run Neovide in the foreground, then restore terminal on exit
      hide_terminal
      trap show_terminal EXIT

      exec ${pkgSet.neovide}/bin/neovide "$@"
    '';
  };
in
{
  # Install Neovide on macOS and provide minimal config
  # Install Neovide wrapper on macOS; it pulls the real Neovide binary via runtimeInputs
  home.packages = lib.mkIf pkgs.stdenv.isDarwin [ neovideWrapper ];

  # Configure Neovide via its standard config file path
  # https://neovide.dev/config-file.html
  home.file = lib.mkIf pkgs.stdenv.isDarwin {
    ".config/neovide/config.toml" = {
      text = ''
        frame = "none"
      '';
      force = true;
    };
  };
}
