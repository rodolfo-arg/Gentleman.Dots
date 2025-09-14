{ pkgs, lib, config, ... }:
let
  sourceDir = ./ghostty;
in
{
  # Single source of truth: XDG path
  home.file.".config/ghostty" = {
    source = sourceDir;
    recursive = true;
    force = true;
  };

  # macOS: place files directly in Application Support (no extra symlink hops)
  home.file."Library/Application Support/ghostty" = lib.mkIf pkgs.stdenv.isDarwin {
    source = sourceDir;
    recursive = true;
    force = true;
  };
}
