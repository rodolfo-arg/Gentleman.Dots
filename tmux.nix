{ pkgs, lib, ... }:

{
  # Intentionally no tmux config files. This leaves tmux at upstream defaults.
  # Tmux is still installed via home.packages in flake.nix.

  # Remove any legacy tmux configs so defaults actually apply
  home.activation.cleanupLegacyTmux = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    for f in "$HOME/.tmux.conf" "$HOME/.config/tmux/tmux.conf"; do
      if [ -e "$f" ]; then
        echo "[tmux] Removing legacy config: $f"
        rm -f -- "$f"
      fi
    done
  '';
}
