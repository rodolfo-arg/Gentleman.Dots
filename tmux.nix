{ pkgs, ... }:

{
  # Instalar TPM (Tmux Plugin Manager)
  # Remove TPM install; we keep tmux minimal for copy-on-select only
  # (No external plugins required for our copy bindings)

  home.file = {
    ".config/tmux/tmux.conf" = {
      text = ''
# Minimal tmux: focus on copy-on-select; no plugins, no status bar

# Floating window (kept for scratch use)
bind-key -n M-g if-shell -F '#{==:#{session_name},scratch}' {
detach-client
} {
# open in the same directory of the current pane
display-popup -d "#{pane_current_path}" -E "tmux new-session -A -s scratch"
}

# Fix colors for the terminal
set -g default-terminal 'tmux-256color'
set -ga terminal-overrides ",xterm-256color:Tc"

# Modo vim
set -g mode-keys vi
if-shell 'uname | grep -q Darwin' 'bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "pbcopy"' 'bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "clip"'

# macOS: mouse-driven copy to clipboard when mouse mode is ON
# - Drag with mouse to select; on release it copies to pbcopy and exits copy-mode
bind -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "pbcopy"
bind -T copy-mode MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "pbcopy"
# Enter copy-mode on mouse drag when not already in copy-mode
bind -n MouseDrag1Pane if -F "#{pane_in_mode}" "send-keys -X begin-selection" "copy-mode -M"

# Keymaps
unbind C-b
set -g prefix C-a
bind C-a send-prefix

unbind %
unbind '"'
bind v split-window -h -c "#{pane_current_path}"
bind d split-window -v -c "#{pane_current_path}"

# Mouse support ON (required for auto‑copy on drag release)
set -g mouse on
# Quick toggle with Prefix + m
bind m set -g mouse \; display-message "mouse: #{?mouse,on,off}"

# Ensure windows resize to the active terminal size and mouse-drag border resizing works
# - window-size latest: track size of the most recently used client
# - aggressive-resize on: prefer the current client's size for the active window
# - explicit MouseDrag1Border bind: keep border drag for pane resizing while preserving copy-on-select bindings
set -g window-size latest
set -g aggressive-resize on
unbind -n MouseDrag1Border
bind -n MouseDrag1Border resize-pane -M

# Integrate with system clipboard
set -g set-clipboard on

# Hide status bar to avoid consuming a line
set -g status off

# Kill all sessions except current
bind K confirm-before -p "Kill all other sessions? (y/n)" "kill-session -a"

# Fix index
set -g base-index 1
setw -g pane-base-index 1

# Fix opencode and gemini cli shift + enter
set -g extended-keys always
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
