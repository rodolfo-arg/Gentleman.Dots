#!/usr/bin/env bash

set -euo pipefail

# =============== Args ===============
CUSTOM_INSTALL=0
usage() {
  cat <<'USAGE'
Gentleman.Dots installer

Usage: bash scripts/install.sh [--custom]

Options:
  --custom   Enable future interactive/custom mode (stub today).
  -h, --help Show this help.
USAGE
}

for arg in "$@"; do
  case "$arg" in
  --custom) CUSTOM_INSTALL=1 ;;
  -h | --help)
    usage
    exit 0
    ;;
  *) ;;
  esac
done

# =============== Styling ===============
if test -t 1; then
  bold=$(tput bold || true)
  reset=$(tput sgr0 || true)
  red=$(tput setaf 1 || true)
  green=$(tput setaf 2 || true)
  yellow=$(tput setaf 3 || true)
  blue=$(tput setaf 4 || true)
else
  bold=""
  reset=""
  red=""
  green=""
  yellow=""
  blue=""
fi

log() { echo "${blue}==>${reset} $*"; }
good() { echo "${green}✔${reset} $*"; }
warn() { echo "${yellow}⚠${reset} $*"; }
err() { echo "${red}✖${reset} $*" >&2; }

# =============== Preconditions ===============
if [[ "$(uname -s)" != "Darwin" ]]; then
  err "This installer targets macOS (Darwin)."
  exit 1
fi

# Require sudo early and keep-alive
log "Requesting administrator privileges (sudo)…"
if ! sudo -v; then
  err "Sudo authorization failed"
  exit 1
fi
while true; do
  sudo -n true
  sleep 60
  kill -0 "$$" || exit
done 2>/dev/null &
SUDO_KEEPALIVE_PID=$!
trap 'kill "${SUDO_KEEPALIVE_PID}" 2>/dev/null || true' EXIT INT TERM

# Ensure Git is available (prerequisite)
if ! command -v git >/dev/null 2>&1; then
  err "Git is required. Install either Xcode Command Line Tools (xcode-select --install) or Homebrew Git."
  echo "Once installed, re-run this script."
  exit 1
fi
good "Git is available"

# Require either Homebrew or a preinstalled Ghostty app
HAS_BREW=0
command -v brew >/dev/null 2>&1 && HAS_BREW=1 || true
HAS_GHOSTTY=0
open -Ra Ghostty >/dev/null 2>&1 && HAS_GHOSTTY=1 || true
if [[ $HAS_BREW -eq 0 && $HAS_GHOSTTY -eq 0 ]]; then
  err "Homebrew or Ghostty is required."
  echo "- Install Homebrew: https://brew.sh (recommended)"
  echo "  or install Ghostty manually: https://ghostty.org/download"
  echo "Re-run this installer afterwards."
  exit 1
fi
if [[ $CUSTOM_INSTALL -eq 1 ]]; then
  warn "Custom mode is not implemented yet; proceeding with the default installation."
fi

# Detect or set repo directory
REPO_URL_DEFAULT="https://github.com/GentlemanProgramming/Gentleman.Dots.git"
REPO_DIR_DEFAULT="$HOME/Gentleman.Dots"
REPO_DIR="${REPO_DIR:-$REPO_DIR_DEFAULT}"
REPO_URL="${REPO_URL:-$REPO_URL_DEFAULT}"

# =============== Clone (if needed) ===============
if [[ -d .git ]] && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  # Running from a git checkout
  REPO_DIR="$(pwd)"
  good "Using existing checkout: $REPO_DIR"
else
  if [[ -d "$REPO_DIR/.git" ]]; then
    good "Found existing repo at $REPO_DIR"
  else
    log "Cloning repository to $REPO_DIR"
    mkdir -p "$(dirname "$REPO_DIR")"
    git clone "$REPO_URL" "$REPO_DIR"
  fi
  cd "$REPO_DIR"
fi

# =============== Install Nix ===============
# First try to load an existing daemon profile so PATH includes nix
if [[ -f "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh" ]]; then
  # shellcheck disable=SC1091
  . "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
fi

if command -v nix >/dev/null 2>&1; then
  good "Nix is already installed"
else
  log "Installing Nix (official installer)…"
  sh <(curl -L https://nixos.org/nix/install)
  # Activate nix daemon profile in current shell (if present) after install
  if [[ -f "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh" ]]; then
    # shellcheck disable=SC1091
    . "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
  fi
fi

# =============== Nix config (experimental features) ===============
log "Ensuring /etc/nix/nix.conf has experimental features enabled"
sudo mkdir -p /etc/nix
# Remove existing experimental-features keys to avoid duplicates, then append desired settings
if [[ -f /etc/nix/nix.conf ]]; then
  sudo sed -E -i '' '/^(extra-)?experimental-features[[:space:]]*=.*/d' /etc/nix/nix.conf || true
  sudo sed -E -i '' '/^build-users-group[[:space:]]*=.*/d' /etc/nix/nix.conf || true
fi
{
  echo "extra-experimental-features = nix-command flakes"
  echo "build-users-group = nixbld"
} | sudo tee -a /etc/nix/nix.conf >/dev/null
good "Updated /etc/nix/nix.conf (flakes + nix-command)"

# Ensure features for this process; also try to reload the daemon (best-effort)
export NIX_CONFIG="extra-experimental-features = nix-command flakes"
if launchctl list | grep -q org.nixos.nix-daemon; then
  sudo launchctl kickstart -k system/org.nixos.nix-daemon || true
fi

# =============== Home Manager (install if missing, per README) ===============
if command -v home-manager >/dev/null 2>&1; then
  good "Home Manager is already installed"
else
  log "Installing Home Manager (channel method)"
  nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
  nix-channel --update
  nix-shell '<home-manager>' -A install
  # Ensure the CLI is available in this shell
  export PATH="$HOME/.nix-profile/bin:$PATH"
  good "Home Manager CLI installed"
fi

# =============== Homebrew (optional, for Ghostty) ===============
BREW_BIN="/opt/homebrew/bin/brew"
if [[ ! -x "$BREW_BIN" ]] && command -v brew >/dev/null 2>&1; then BREW_BIN="$(command -v brew)"; fi
if [[ ! -x "$BREW_BIN" ]]; then
  warn "Homebrew not found. Ghostty app install will be skipped (assuming preinstalled or manual)."
else
  eval "$($BREW_BIN shellenv)"
  if ! brew list --cask ghostty >/dev/null 2>&1; then
    log "Installing Ghostty (Homebrew cask)"
    brew install --cask ghostty || warn "Ghostty install skipped/failed. You can install it later."
  else
    good "Ghostty already installed via Homebrew"
  fi
fi

# =============== Home Manager switch ===============
# Pick correct flake output based on CPU architecture
ARCH="$(uname -m)"
case "$ARCH" in
arm64) FLAKE_SELECTOR="gentleman-macos-arm" ;;
x86_64) FLAKE_SELECTOR="gentleman-macos-intel" ;;
*) FLAKE_SELECTOR="gentleman" ;;
esac
log "Applying Home Manager configuration (flake: #$FLAKE_SELECTOR)"
# Ensure flake.nix uses the current macOS user/home
FLAKE_FILE="$REPO_DIR/flake.nix"
if [[ -f "$FLAKE_FILE" ]]; then
  DETECTED_USER="${USER:-$(id -un)}"
  DETECTED_HOME="${HOME:-/Users/${DETECTED_USER}}"

  # Replace default username/homeDirectory defaults inside mkHomeConfiguration
  # Be tolerant of whitespace variations; macOS sed requires -i ''
  sed -E -i '' 's/(username[[:space:]]*\?[[:space:]]*")[^"]*(")/\1'"$DETECTED_USER"'\2/' "$FLAKE_FILE" || true
  sed -E -i '' 's|(homeDirectory[[:space:]]*\?[[:space:]]*")[^"]*(")|\1'"$DETECTED_HOME"'\2|' "$FLAKE_FILE" || true
  good "Personalized flake.nix for user '${DETECTED_USER}'"
  # Optionally commit the change so flake evaluations that prefer Git sources pick it up
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    if [[ -n "$(git status --porcelain -- flake.nix)" ]]; then
      log "Committing flake.nix personalization"
      git add flake.nix || warn "git add failed; proceeding without commit"
      git -c user.name="Gentleman Installer" -c user.email="installer@local" \
        commit -m "installer: personalize flake.nix for user ${DETECTED_USER}" ||
        warn "git commit failed; proceeding without commit"
    fi
  fi
else
  warn "flake.nix not found at $FLAKE_FILE — skipping user personalization"
fi
log "Using local home-manager CLI"
home-manager switch --flake "$REPO_DIR#$FLAKE_SELECTOR"
good "Home Manager switch complete"

# Commit flake.lock changes if updated during the switch (best-effort)
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  if [[ -n "$(git status --porcelain -- flake.lock)" ]]; then
    log "Committing updated flake.lock"
    git add flake.lock || warn "git add flake.lock failed; continuing"
    git -c user.name="Gentleman Installer" -c user.email="installer@local" \
      commit -m "installer: update flake.lock after switch" ||
      warn "git commit flake.lock failed; continuing"
  fi
fi

# =============== Default shell: zsh from HM profile ===============
HM_ZSH="$HOME/.local/state/nix/profiles/home-manager/home-path/bin/zsh"
if [[ -x "$HM_ZSH" ]]; then
  if ! grep -q "$HM_ZSH" /etc/shells; then
    log "Registering HM zsh in /etc/shells"
    echo "$HM_ZSH" | sudo tee -a /etc/shells >/dev/null
  fi
  if [[ "$(dscl . -read /Users/$USER UserShell 2>/dev/null | awk '{print $2}')" != "$HM_ZSH" ]]; then
    log "Changing default shell to HM zsh"
    sudo chsh -s "$HM_ZSH" "$USER" || warn "Could not change default shell automatically"
  fi
  good "Zsh registered and set (or already set)"
else
  warn "HM zsh not found at $HM_ZSH — skipping default shell change"
fi

# =============== Finish ===============
echo
good "Installation complete."
echo "- Open Ghostty (installed via Homebrew if available)"
echo "- Start a new terminal session to use your Home Manager environment"

# Future: custom install mode
# - Detect gum/fzf for interactive selection
# - Export choices as environment variables for HM modules to read
# - For now, we always install the default config

# =============== Launch Ghostty and close current terminal ===============
# Try to launch Ghostty for a fresh session
if open -Ra Ghostty >/dev/null 2>&1; then
  log "Launching Ghostty"
  open -a Ghostty || warn "Could not launch Ghostty automatically"
  sleep 1
else
  warn "Ghostty app not found; skipping launch"
fi

# If we are not already in Ghostty, attempt to close the current terminal
case "${TERM_PROGRAM:-}" in
"Apple_Terminal")
  log "Closing Terminal.app window"
  osascript <<'OSA' >/dev/null 2>&1 || true
tell application "Terminal"
  try
    if (count of windows) > 0 then close front window
    if (count of windows) is 0 then quit
  end try
end tell
OSA
  ;;
"iTerm.app")
  log "Closing iTerm.app"
  osascript -e 'tell application "iTerm" to quit' >/dev/null 2>&1 || true
  ;;
"Ghostty")
  # Already in Ghostty; do nothing
  ;;
*)
  # Unknown terminal; best-effort exit of this shell
  ;;
esac

exit 0
