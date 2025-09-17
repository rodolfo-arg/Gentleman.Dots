{ pkgs, lib, unstablePkgs ? null, ... }:
let
  # Prefer unstablePkgs when provided; fallback to pkgs
  pkgSet = if unstablePkgs == null then pkgs else unstablePkgs;
in
{
  # Install Neovide and provide a portable "svim" launcher on macOS and Linux
  home.packages = lib.mkIf (pkgs.stdenv.isDarwin || pkgs.stdenv.isLinux) [
    pkgSet.neovide
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
