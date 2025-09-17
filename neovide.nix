{ pkgs, lib, unstablePkgs ? null, ... }:
let
  # Prefer unstablePkgs when provided; fallback to pkgs
  pkgSet = if unstablePkgs == null then pkgs else unstablePkgs;
in
{
  # Install Neovide and provide a portable "svim" launcher on macOS and Linux
  home.packages = lib.mkIf (pkgs.stdenv.isDarwin || pkgs.stdenv.isLinux) [
    pkgSet.neovide
    # Linux: override neovide with a wrapper that forces software GL and X11
    (lib.optional pkgs.stdenv.isLinux (pkgs.writeShellScriptBin "neovide" ''
      #!/usr/bin/env bash
      # Prefer software rendering in VMs; winit prefers X11 for broader compat
      export LIBGL_ALWAYS_SOFTWARE="''${LIBGL_ALWAYS_SOFTWARE:-1}"
      export MESA_LOADER_DRIVER_OVERRIDE="''${MESA_LOADER_DRIVER_OVERRIDE:-llvmpipe}"
      if [ -n "${DISPLAY-}" ]; then
        export WINIT_UNIX_BACKEND="''${WINIT_UNIX_BACKEND:-x11}"
      fi
      exec ${pkgSet.neovide}/bin/neovide "$@"
    ''))
    # Convenience helper
    (lib.optional pkgs.stdenv.isLinux (pkgs.writeShellScriptBin "neovide-soft" ''
      #!/usr/bin/env bash
      export LIBGL_ALWAYS_SOFTWARE=1
      export MESA_LOADER_DRIVER_OVERRIDE=llvmpipe
      export WINIT_UNIX_BACKEND=x11
      exec ${pkgSet.neovide}/bin/neovide "$@"
    ''))
    (pkgs.writeShellScriptBin "svim" ''
      #!/usr/bin/env bash
      if [ $# -eq 0 ]; then
        exec neovide --fork
      else
        exec neovide --fork "$@"
      fi
    '')
  ];

  # Neovide config (XDG path)
  home.file.".config/neovide/config.toml" = lib.mkIf (pkgs.stdenv.isDarwin || pkgs.stdenv.isLinux) {
    text = ''
      frame = "none"
    '';
    force = true;
  };
}
