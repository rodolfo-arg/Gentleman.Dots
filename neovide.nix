{ pkgs, lib, unstablePkgs ? null, ... }:
let
  # Prefer unstablePkgs when provided; fallback to pkgs
  pkgSet = if unstablePkgs == null then pkgs else unstablePkgs;
in
{
  # Install Neovide on macOS only
  home.packages = lib.mkIf pkgs.stdenv.isDarwin [ pkgSet.neovide ];

  # Neovide config (macOS/Linux XDG path)
  home.file.".config/neovide/config.toml" = lib.mkIf pkgs.stdenv.isDarwin {
    text = ''
      frame = "none"
    '';
    force = true;
  };

  # zsh function to launch Neovide as "svim"
  programs.zsh.initExtra = lib.mkIf pkgs.stdenv.isDarwin ''
    svim() {
      if [ $# -eq 0 ]; then
        neovide --fork
      else
        neovide --fork "$@"
      fi
      exit
    }
  '';
}
