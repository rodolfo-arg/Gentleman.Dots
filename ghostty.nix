{ pkgs, lib, config, ... }:
let
  sourceDir = ./ghostty;
in
{
  # On Linux VMs/drivers, GTK4 + OpenGL can crash. Provide a wrapper that
  # forces software rendering for Ghostty to avoid EGL issues.
  home.packages = lib.optionals pkgs.stdenv.isLinux [
    (pkgs.writeShellScriptBin "ghostty" ''
      #!/usr/bin/env bash
      export GSK_RENDERER="${GSK_RENDERER:-cairo}"
      # Fallback to software GL if drivers are incomplete
      export LIBGL_ALWAYS_SOFTWARE="${LIBGL_ALWAYS_SOFTWARE:-1}"
      exec ${pkgs.ghostty}/bin/ghostty "$@"
    '')
  ];

  # Single source of truth: XDG path
  home.file.".config/ghostty" = {
    source = sourceDir;
    recursive = true;
    force = true;
  };

  # macOS: Ghostty uses bundle path under Application Support
  # Correct path: ~/Library/Application Support/com.mitchellh.ghostty
  home.file."Library/Application Support/com.mitchellh.ghostty" = lib.mkIf pkgs.stdenv.isDarwin {
    source = sourceDir;
    recursive = true;
    force = true;
  };

  # Cleanup: if an older path ".../ghostty" exists as a Nix symlink, remove it
  home.activation.cleanupOldGhosttyPath = lib.mkIf pkgs.stdenv.isDarwin (
    lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      OLD_PATH="$HOME/Library/Application Support/ghostty"
      if [ -L "$OLD_PATH" ]; then
        TARGET=$(readlink "$OLD_PATH" || true)
        case "$TARGET" in
          /nix/store/*)
            echo "Removing old Ghostty symlink: $OLD_PATH -> $TARGET"
            rm -f "$OLD_PATH"
            ;;
        esac
      fi
    ''
  );
}
