{ pkgs, ... }:

{
  home.file = {
    ".config/tmux/tmux.conf" = {
      text = ''
# Standard tmux with only auto‑yank on selection

# Keep default keybindings and status. Only add clipboard-on-select behavior.

# Use vi-style copy-mode so `y` works as expected
set -g mode-keys vi

# Enable mouse so dragging selects text in copy-mode
set -g mouse on

# Copy to system clipboard on yank in copy-mode (macOS vs others)
if-shell 'uname | grep -q Darwin' \
  'bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "pbcopy"' \
  'bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "xclip -sel clip -i"'

# When finishing a mouse selection in copy-mode, copy to clipboard
if-shell 'uname | grep -q Darwin' \
  'bind -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "pbcopy"' \
  'bind -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "xclip -sel clip -i"'

# If not already in copy-mode, start it on mouse drag so selection works
bind -n MouseDrag1Pane if -F "#{pane_in_mode}" "send-keys -X begin-selection" "copy-mode -M"
      '';
    };
    # Ensure tmux reads the XDG config by sourcing it from the legacy path
    ".tmux.conf" = {
      text = ''
source-file ~/.config/tmux/tmux.conf
      '';
      force = true;
    };
  };
}
