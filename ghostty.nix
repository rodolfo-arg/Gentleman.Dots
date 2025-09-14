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

  # macOS convenience symlink to native location, pointing to XDG path
  home.file."Library/Application Support/ghostty" = lib.mkIf pkgs.stdenv.isDarwin {
    source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/ghostty";
    force = true;
  };
}
