{ pkgs, lib, unstablePkgs ? null, ... }:
let
  # Prefer unstablePkgs when provided; fallback to pkgs
  pkgSet = if unstablePkgs == null then pkgs else unstablePkgs;
in
{
  # Install Neovide on macOS and provide minimal config
  home.packages = lib.mkIf pkgs.stdenv.isDarwin [ pkgSet.neovide ];

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
