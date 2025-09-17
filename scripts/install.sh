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
    -h|--help) usage; exit 0 ;;
    *) ;;
  esac
done

# =============== Styling ===============
if test -t 1; then
  bold=$(tput bold || true); reset=$(tput sgr0 || true)
  red=$(tput setaf 1 || true); green=$(tput setaf 2 || true)
  yellow=$(tput setaf 3 || true); blue=$(tput setaf 4 || true)
else bold=""; reset=""; red=""; green=""; yellow=""; blue=""; fi

log()  { echo "${blue}==>${reset} $*"; }
good() { echo "${green}✔${reset} $*"; }
warn() { echo "${yellow}⚠${reset} $*"; }
err()  { echo "${red}✖${reset} $*" >&2; }

# =============== Preconditions ===============
OS_NAME=$(uname -s)
case "$OS_NAME" in
  Darwin) PLATFORM="darwin" ;;
  Linux) PLATFORM="linux" ;;
  *) err "Unsupported OS: $OS_NAME"; exit 1 ;;
esac

# Require sudo early and keep-alive
log "Requesting administrator privileges (sudo)…"
if ! sudo -v; then err "Sudo authorization failed"; exit 1; fi
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
SUDO_KEEPALIVE_PID=$!
trap 'kill "${SUDO_KEEPALIVE_PID}" 2>/dev/null || true' EXIT INT TERM

# Ensure Git is available (prerequisite)
if ! command -v git >/dev/null 2>&1; then
  err "Git is required. Install either Xcode Command Line Tools (xcode-select --install) or Homebrew Git."
  echo "Once installed, re-run this script."
  exit 1
fi
good "Git is available"

# macOS only: require either Homebrew (to install Ghostty) or a preinstalled Ghostty app
if [[ "$PLATFORM" == "darwin" ]]; then
  HAS_BREW=0; command -v brew >/dev/null 2>&1 && HAS_BREW=1 || true
  HAS_GHOSTTY=0; open -Ra Ghostty >/dev/null 2>&1 && HAS_GHOSTTY=1 || true
  if [[ $HAS_BREW -eq 0 && $HAS_GHOSTTY -eq 0 ]]; then
    err "Homebrew or Ghostty is required on macOS."
    echo "- Install Homebrew: https://brew.sh (recommended)"
    echo "  or install Ghostty manually: https://ghostty.org/download"
    echo "Re-run this installer afterwards."
    exit 1
  fi
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
# Helper to load Nix into current shell on both macOS and Linux
load_nix_env() {
  if [[ -f "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh" ]]; then
    # shellcheck disable=SC1091
    . "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
  fi
  # Linux single-user profile (fresh installs)
  if [[ -f "$HOME/.nix-profile/etc/profile.d/nix.sh" ]]; then
    # shellcheck disable=SC1091
    . "$HOME/.nix-profile/etc/profile.d/nix.sh"
  fi
}

# First try to load an existing profile so PATH includes nix
load_nix_env
# Ensure user profile bins are on PATH for this shell session (incl. home-manager)
export PATH="$HOME/.nix-profile/bin:/nix/var/nix/profiles/default/bin:$PATH"

# Normalize login shell environment files to avoid stale hm-session-vars errors
ensure_login_shell_env() {
  local marker="# GENTLEMAN_DOTS_HM_ENV"
  local snippet
  read -r -d '' snippet <<'SNIP' || true
# GENTLEMAN_DOTS_HM_ENV
# Prefer Home Manager's home-path session vars and PATH
if [ -f "$HOME/.local/state/nix/profiles/home-manager/home-path/etc/profile.d/hm-session-vars.sh" ]; then
  unset __HM_SESS_VARS_SOURCED
  . "$HOME/.local/state/nix/profiles/home-manager/home-path/etc/profile.d/hm-session-vars.sh"
elif [ -f "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then
  . "$HOME/.nix-profile/etc/profile.d/nix.sh"
fi
export PATH="$HOME/.local/state/nix/profiles/home-manager/home-path/bin:$HOME/.nix-profile/bin:$PATH"
SNIP

  local appended=0
  for f in "$HOME/.bash_profile" "$HOME/.profile" "$HOME/.bash_login" "$HOME/.bashrc"; do
    [ -e "$f" ] || continue
    # Comment out any unconditional sourcing of the old hm-session-vars path
    if grep -q "/.nix-profile/etc/profile.d/hm-session-vars.sh" "$f"; then
      log "Patching legacy hm-session-vars reference in $f"
      cp "$f" "$f.bak" 2>/dev/null || true
      # Comment direct 'source' or '.' calls unconditionally
      sed -i 's~^[[:space:]]*\(source\|\.\)[[:space:]]\+\$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh~# \0~' "$f" 2>/dev/null || true
      sed -i 's~^[[:space:]]*\(source\|\.\)[[:space:]]\+\~/.nix-profile/etc/profile.d/hm-session-vars.sh~# \0~' "$f" 2>/dev/null || true
      sed -i 's~^[[:space:]]*\(source\|\.\)[[:space:]]\+/home/.*/\.nix-profile/etc/profile.d/hm-session-vars.sh~# \0~' "$f" 2>/dev/null || true
    fi
    # Append our snippet once
    if ! grep -q "^${marker}$" "$f"; then
      if [ -w "$f" ]; then
        (printf '\n%s\n' "$snippet" >> "$f") || true
        appended=1
      else
        warn "Cannot write to $f (permission denied). Skipping env snippet for this file."
      fi
    fi
  done

  # Fallback: if nothing was appended, try to create or append to ~/.bashrc
  if [ "$appended" -eq 0 ]; then
    local f="$HOME/.bashrc"
    if ! grep -q "^${marker}$" "$f" 2>/dev/null; then
      log "Appending environment snippet to $f (fallback)"
      (touch "$f" 2>/dev/null || true)
      if [ -w "$f" ]; then
        (printf '\n%s\n' "$snippet" >> "$f") || true
      else
        warn "Fallback also failed: cannot write to $f. Please add the following snippet manually to your bash init file:"
        printf '%s\n' "$snippet"
      fi
    fi
  fi
}

## delay environment snippet until after we purge conflicts and backups

# =============== Purge conflicting dotfiles (pre-link cleanup) ===============
# Home Manager refuses to clobber existing files it manages. Remove a small,
# well-defined set of common dotfiles that this flake manages to avoid failures.
purge_conflicting_dotfiles() {
  log "Removing known conflicting dotfiles for Home Manager"
  local targets=(
    "$HOME/.profile"
    "$HOME/.bashrc"
    "$HOME/.bash_profile"
    "$HOME/.bash_login"
    "$HOME/.zshrc"
    "$HOME/.zprofile"
    "$HOME/.zlogin"
    "$HOME/.config/gh/config.yml"
  )
  local removed=0
  for t in "${targets[@]}"; do
    if [ -e "$t" ] || [ -L "$t" ]; then
      rm -f -- "$t" 2>/dev/null && echo "Removed: $t" && removed=1 || true
    fi
  done
  if [ "$removed" -eq 1 ]; then
    good "Removed conflicting dotfiles"
  else
    log "No conflicting dotfiles to remove"
  fi
}

purge_conflicting_dotfiles

# =============== Cleanup previous Home Manager backups (.backup) ===============
# Some earlier runs may have created *.backup files that block activation when
# using backup extensions. We proactively remove them.
cleanup_hm_backups() {
  log "Scanning for old Home Manager backups (*.backup)"
  local removed=0
  # Top-level dotfiles
  while IFS= read -r -d '' f; do
    rm -f -- "$f" && echo "Removed: $f" && removed=1 || true
  done < <(find "$HOME" -maxdepth 1 -type f -name '*.backup' -print0 2>/dev/null)

  # Under ~/.config
  if [ -d "$HOME/.config" ]; then
    while IFS= read -r -d '' f; do
      rm -f -- "$f" && echo "Removed: $f" && removed=1 || true
    done < <(find "$HOME/.config" -type f -name '*.backup' -print0 2>/dev/null)
  fi

  if [ "$removed" -eq 1 ]; then
    good "Removed previous .backup files"
  else
    log "No .backup files found"
  fi
}

cleanup_hm_backups

# Now attempt environment snippet adjustments (best-effort)
ensure_login_shell_env

if command -v nix >/dev/null 2>&1; then
  good "Nix is already installed"
else
  log "Installing Nix (official installer)…"
  sh <(curl -L https://nixos.org/nix/install)
  # Activate nix environment in current shell after install
  load_nix_env
fi

# =============== Nix config (experimental features) ===============
log "Ensuring /etc/nix/nix.conf has experimental features enabled"
sudo mkdir -p /etc/nix

# Portable in-place sed wrapper (macOS vs GNU sed)
sed_in_place() {
  if sed --version >/dev/null 2>&1; then
    sudo sed -E -i "$@"
  else
    local file
    file="${@: -1}"
    # shellcheck disable=SC2295
    sudo sed -E -i '' "${@:1:$(($#-1))}" "$file"
  fi
}

# Remove existing experimental-features keys to avoid duplicates, then append desired settings
if [[ -f /etc/nix/nix.conf ]]; then
  sed_in_place '/^(extra-)?experimental-features[[:space:]]*=.*/d' /etc/nix/nix.conf || true
  sed_in_place '/^build-users-group[[:space:]]*=.*/d' /etc/nix/nix.conf || true
fi
{
  echo "extra-experimental-features = nix-command flakes"
  echo "build-users-group = nixbld"
} | sudo tee -a /etc/nix/nix.conf >/dev/null
good "Updated /etc/nix/nix.conf (flakes + nix-command)"

# Ensure features for this process; also try to reload the daemon (best-effort)
export NIX_CONFIG="extra-experimental-features = nix-command flakes"
if [[ "$PLATFORM" == "darwin" ]]; then
  if launchctl list | grep -q org.nixos.nix-daemon; then
    sudo launchctl kickstart -k system/org.nixos.nix-daemon || true
  fi
else
  if command -v systemctl >/dev/null 2>&1; then
    sudo systemctl reload nix-daemon >/dev/null 2>&1 || true
  fi
fi

# =============== Home Manager (install if missing, per README) ===============
HM_READY=0
if command -v home-manager >/dev/null 2>&1; then
  HM_READY=1
fi

# =============== Homebrew (optional, for Ghostty) ===============
if [[ "$PLATFORM" == "darwin" ]]; then
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
fi

# =============== Home Manager switch ===============
# Pick correct flake output based on CPU architecture
ARCH="$(uname -m)"
case "$PLATFORM:$ARCH" in
  darwin:arm64)   FLAKE_SELECTOR="gentleman-macos-arm" ;;
  darwin:x86_64)  FLAKE_SELECTOR="gentleman-macos-intel" ;;
  linux:aarch64)  FLAKE_SELECTOR="gentleman-linux-arm" ;;
  linux:arm64)    FLAKE_SELECTOR="gentleman-linux-arm" ;;
  linux:x86_64)   FLAKE_SELECTOR="gentleman-linux-intel" ;;
  *)              FLAKE_SELECTOR="gentleman" ;;
esac
log "Applying Home Manager configuration (flake: #$FLAKE_SELECTOR)"
# Ensure flake.nix uses the current macOS user/home
FLAKE_FILE="$REPO_DIR/flake.nix"
if [[ -f "$FLAKE_FILE" ]]; then
  DETECTED_USER="${USER:-$(id -un)}"
  DETECTED_HOME="${HOME}"

  # Replace default username/homeDirectory defaults inside mkHomeConfiguration
  # Be tolerant of whitespace variations; macOS sed requires -i ''
  if sed --version >/dev/null 2>&1; then
    sed -E -i 's/(username[[:space:]]*\?[[:space:]]*")[^"]*(")/\1'"$DETECTED_USER"'\2/' "$FLAKE_FILE" || true
    sed -E -i 's|(homeDirectory[[:space:]]*\?[[:space:]]*")[^"]*(")|\1'"$DETECTED_HOME"'\2|' "$FLAKE_FILE" || true
  else
    sed -E -i '' 's/(username[[:space:]]*\?[[:space:]]*")[^"]*(")/\1'"$DETECTED_USER"'\2/' "$FLAKE_FILE" || true
    sed -E -i '' 's|(homeDirectory[[:space:]]*\?[[:space:]]*")[^"]*(")|\1'"$DETECTED_HOME"'\2|' "$FLAKE_FILE" || true
  fi
  good "Personalized flake.nix for user '${DETECTED_USER}'"
  # Optionally commit the change so flake evaluations that prefer Git sources pick it up
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    if [[ -n "$(git status --porcelain -- flake.nix)" ]]; then
      log "Committing flake.nix personalization"
      git add flake.nix || warn "git add failed; proceeding without commit"
      git -c user.name="Gentleman Installer" -c user.email="installer@local" \
        commit -m "installer: personalize flake.nix for user ${DETECTED_USER}" \
        || warn "git commit failed; proceeding without commit"
    fi
  fi
else
  warn "flake.nix not found at $FLAKE_FILE — skipping user personalization"
fi
APPLY_OK=0
log "Applying Home Manager configuration (prefer nix run)"
if nix --extra-experimental-features 'nix-command flakes' \
  run github:nix-community/home-manager -- switch --flake "$REPO_DIR#$FLAKE_SELECTOR"; then
  APPLY_OK=1
else
  warn "nix run home-manager failed. Trying nix shell with home-manager."
  if nix --extra-experimental-features 'nix-command flakes' \
    shell github:nix-community/home-manager#home-manager -c home-manager switch --flake "$REPO_DIR#$FLAKE_SELECTOR"; then
    APPLY_OK=1
  else
    warn "nix shell home-manager failed. Trying installed CLI if available."
    if [[ $HM_READY -eq 1 ]] && command -v home-manager >/dev/null 2>&1; then
      log "Using local home-manager CLI"
      if home-manager switch --flake "$REPO_DIR#$FLAKE_SELECTOR"; then
        APPLY_OK=1
      fi
    else
      # Attempt to install the home-manager CLI into the user profile, then retry
      log "Installing home-manager CLI to user profile via nix profile install"
      if nix --extra-experimental-features 'nix-command flakes' \
        profile install github:nix-community/home-manager#home-manager; then
        export PATH="$HOME/.nix-profile/bin:/nix/var/nix/profiles/default/bin:$PATH"
        if command -v home-manager >/dev/null 2>&1; then
          log "Retrying with installed home-manager CLI"
          if home-manager switch --flake "$REPO_DIR#$FLAKE_SELECTOR"; then
            APPLY_OK=1
          fi
        fi
      else
        warn "Failed to install home-manager CLI via nix profile"
      fi
    fi
  fi
fi
if [[ $APPLY_OK -ne 1 ]]; then
  err "Home Manager switch failed. Ensure network access to fetch inputs or install the home-manager CLI."
  exit 1
fi
good "Home Manager switch complete"

# Load Home Manager session variables and ensure new tools are in PATH for this shell session
HM_SESS_VARS="$HOME/.local/state/nix/profiles/home-manager/home-path/etc/profile.d/hm-session-vars.sh"
if [[ -f "$HM_SESS_VARS" ]]; then
  # Tolerate nounset when sourcing HM session vars
  _HM_NOUNSET_WAS_ON=
  if set -o | grep -q 'nounset[[:space:]]*on'; then _HM_NOUNSET_WAS_ON=1; set +u; fi
  unset __HM_SESS_VARS_SOURCED || true
  # shellcheck disable=SC1090
  . "$HM_SESS_VARS"
  if [ -n "${_HM_NOUNSET_WAS_ON-}" ]; then set -u; unset _HM_NOUNSET_WAS_ON; fi
fi
export PATH="$HOME/.local/state/nix/profiles/home-manager/home-path/bin:$PATH"
hash -r || true

# Commit flake.lock changes if updated during the switch (best-effort)
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  if [[ -n "$(git status --porcelain -- flake.lock)" ]]; then
    log "Committing updated flake.lock"
    git add flake.lock || warn "git add flake.lock failed; continuing"
    git -c user.name="Gentleman Installer" -c user.email="installer@local" \
      commit -m "installer: update flake.lock after switch" \
      || warn "git commit flake.lock failed; continuing"
  fi
fi

# =============== Default shell: match current shell (bash or zsh) ===============
HM_ZSH="$HOME/.local/state/nix/profiles/home-manager/home-path/bin/zsh"
HM_BASH="$HOME/.local/state/nix/profiles/home-manager/home-path/bin/bash"

# Ensure HM shells are registered in /etc/shells if present
for _sh in "$HM_BASH" "$HM_ZSH"; do
  if [[ -x "$_sh" ]] && ! grep -qxF "$_sh" /etc/shells; then
    log "Registering $_sh in /etc/shells"
    printf '%s\n' "$_sh" | sudo tee -a /etc/shells >/dev/null || true
  fi
done

# Detect current login shell path
if [[ "$PLATFORM" == "darwin" ]]; then
  CURRENT_SHELL_PATH=$(dscl . -read "/Users/$USER" UserShell 2>/dev/null | awk '{print $2}')
else
  CURRENT_SHELL_PATH=$(getent passwd "$USER" | cut -d: -f7)
fi
CURRENT_SHELL_NAME=$(basename "${CURRENT_SHELL_PATH:-}")

TARGET_SHELL=""
case "$CURRENT_SHELL_NAME" in
  zsh)  TARGET_SHELL="$HM_ZSH" ;;
  bash) TARGET_SHELL="$HM_BASH" ;;
  *)    TARGET_SHELL="$HM_ZSH" ;; # default preference if unknown
esac

if [[ -x "$TARGET_SHELL" ]]; then
  if ! grep -q "$TARGET_SHELL" /etc/shells; then
    log "Registering $TARGET_SHELL in /etc/shells"
    echo "$TARGET_SHELL" | sudo tee -a /etc/shells >/dev/null
  fi
  if [[ "$CURRENT_SHELL_PATH" != "$TARGET_SHELL" ]]; then
    log "Changing default shell to $TARGET_SHELL"
    if [[ "$PLATFORM" == "darwin" ]]; then
      sudo chsh -s "$TARGET_SHELL" "$USER" || warn "Could not change default shell automatically"
    else
      chsh -s "$TARGET_SHELL" "$USER" \
        || sudo chsh -s "$TARGET_SHELL" "$USER" \
        || sudo usermod -s "$TARGET_SHELL" "$USER" \
        || warn "Could not change default shell automatically"
    fi
  fi
  good "Default shell is set to $(basename "$TARGET_SHELL") (or already set)"
else
  warn "Target shell not found/executable at $TARGET_SHELL — skipping default shell change"
fi

# Hint: $SHELL in the current process won't update automatically
if [[ "${SHELL:-}" != "$TARGET_SHELL" ]]; then
  warn "Current process shell remains $SHELL. Open a new terminal or run: exec \"$TARGET_SHELL\" -l"
fi

# =============== Finish ===============
echo
good "Installation complete."
if [[ "$PLATFORM" == "darwin" ]]; then
  echo "- Open Ghostty (installed via Homebrew if available)"
fi
echo "- Start a new terminal session to use your Home Manager environment"

# Future: custom install mode
# - Detect gum/fzf for interactive selection
# - Export choices as environment variables for HM modules to read
# - For now, we always install the default config

# =============== Launch Ghostty and close current terminal ===============
# Try to launch Ghostty for a fresh session
if [[ "$PLATFORM" == "darwin" ]]; then
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
fi

exit 0
