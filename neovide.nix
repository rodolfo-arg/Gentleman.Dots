{ pkgs, lib, unstablePkgs ? null, ... }:
let
  # Prefer unstablePkgs when provided; fallback to pkgs
  pkgSet = if unstablePkgs == null then pkgs else unstablePkgs;
in
{
  # Install Neovide and provide a portable "svim" launcher on macOS and Linux
  home.packages =
    (if pkgs.stdenv.isDarwin || pkgs.stdenv.isLinux then
      ([
        pkgSet.neovide
        (pkgs.writeShellScriptBin "svim" ''
          #!/usr/bin/env bash
          # On Linux, prefer software GL and X11 for compatibility
          if [ "$(uname -s)" = "Linux" ]; then
            export LIBGL_ALWAYS_SOFTWARE="''${LIBGL_ALWAYS_SOFTWARE:-1}"
            export MESA_LOADER_DRIVER_OVERRIDE="''${MESA_LOADER_DRIVER_OVERRIDE:-llvmpipe}"
            if [ -n "''${DISPLAY-}" ]; then
              export WINIT_UNIX_BACKEND="''${WINIT_UNIX_BACKEND:-x11}"
            fi
          fi
          if [ $# -eq 0 ]; then
            exec ${pkgSet.neovide}/bin/neovide --fork
          else
            exec ${pkgSet.neovide}/bin/neovide --fork "$@"
          fi
        '')
      ] ++ (if pkgs.stdenv.isLinux then [
        (pkgs.writeShellScriptBin "neovide-soft" ''
          #!/usr/bin/env bash
          export LIBGL_ALWAYS_SOFTWARE=1
          export MESA_LOADER_DRIVER_OVERRIDE=llvmpipe
          export WINIT_UNIX_BACKEND=x11
          exec ${pkgSet.neovide}/bin/neovide "$@"
        '')
      ] else []))
    else []);

  # Neovide config (XDG path)
  home.file.".config/neovide/config.toml" = lib.mkIf (pkgs.stdenv.isDarwin || pkgs.stdenv.isLinux) {
    text = ''
      frame = "none"
    '';
    force = true;
  };
}
