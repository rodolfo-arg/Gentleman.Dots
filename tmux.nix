{ lib, pkgs, ... }:
let
  isDarwin = pkgs.stdenv.isDarwin;
in
{
  # Configure tmux only on macOS, following repo scope
  programs.tmux = lib.mkIf isDarwin {
    # Enable is centralized in flake.nix per repo pattern

    aggressiveResize = true;
    clock24 = true;
    mouse = true;
    keyMode = "vi";
    baseIndex = 1;
    escapeTime = 0;
    historyLimit = 10000;
    terminal = "xterm-256color";
    shell = "${pkgs.zsh}/bin/zsh";

    # Keep plugins minimal and stable
    plugins = with pkgs.tmuxPlugins; [ sensible yank ];

    extraConfig = ''
      # Use truecolor when available
      set -ga terminal-overrides ',xterm-256color:RGB'

      # Prefer top status bar to match editor-centric layout
      set -g status-position top

      # Prefix = Ctrl-a (unbind default)
      unbind C-b
      set -g prefix C-a
      bind C-a send-prefix

      # Toggle mouse quickly (Prefix + m)
      bind m set -g mouse \; display-message "mouse: #{?mouse,on,off}"

      # Copy selection to macOS clipboard on mouse drag end
      bind -T copy-mode-vi MouseDragEnd1Pane send -X copy-pipe-and-cancel "pbcopy"

      # Vi-style selection in copy mode
      setw -g mode-keys vi
    '';
  };
}

