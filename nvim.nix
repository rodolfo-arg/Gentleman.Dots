{ lib, ... }:
{
  # Declaratively manage Neovim config via Home Manager
  home.file.".config/nvim" = {
    source = ./nvim;
    recursive = true;
    force = true;
  };

  # Keep Neovim plugins up to date on every switch
  home.activation.nvimLazySync = lib.hm.dag.entryAfter ["linkGeneration"] ''
    if command -v nvim >/dev/null 2>&1; then
      echo "[nvim] Syncing plugins (Lazy)"
      nvim --headless "+Lazy! sync" +qa || true
    fi
  '';
}
