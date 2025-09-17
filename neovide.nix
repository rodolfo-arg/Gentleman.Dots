{ pkgs, lib, unstablePkgs ? null, ... }:
let
  # Prefer unstablePkgs when provided; fallback to pkgs
  pkgSet = if unstablePkgs == null then pkgs else unstablePkgs;
in
{
  # Install Neovide on macOS and Linux
  home.packages = lib.mkIf (pkgs.stdenv.isDarwin || pkgs.stdenv.isLinux) [ pkgSet.neovide ];

  # Neovide config (XDG path)
  home.file.".config/neovide/config.toml" = lib.mkIf (pkgs.stdenv.isDarwin || pkgs.stdenv.isLinux) {
    text = ''
      frame = "none"
    '';
    force = true;
  };

  # Provide a cross-shell launcher "svim" without touching deprecated zsh.initExtra
  home.packages = lib.mkIf (pkgs.stdenv.isDarwin || pkgs.stdenv.isLinux) [
    (pkgs.writeShellScriptBin "svim" ''
      #!/usr/bin/env bash
      if [ $# -eq 0 ]; then
        exec neovide --fork
      else
        exec neovide --fork "$@"
      fi
    '')
  ];
}
