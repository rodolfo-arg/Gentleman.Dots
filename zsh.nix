{ config, pkgs, lib, ... }:
{
  programs.zsh = {
    # Enable completions
    enableCompletion = false;

    # zplug handled manually in initContent to avoid deprecation warnings
    zplug.enable = false;

    # Full .zshrc content (initExtra is deprecated; use initContent)
    initContent = ''
      typeset -U path cdpath fpath manpath
      # Ensure HM profile bins are always in PATH (interactive + non-login)
      export PATH="$HOME/.local/state/nix/profiles/home-manager/home-path/bin:$HOME/.nix-profile/bin:$PATH"
      for profile in ''${(z)NIX_PROFILES}; do
        fpath+=($profile/share/zsh/site-functions $profile/share/zsh/$ZSH_VERSION/functions $profile/share/zsh/vendor-completions)
      done
      # asdf provides native zsh completions; add them to fpath before compinit
      fpath+=(${pkgs.asdf-vm}/share/asdf-vm/completions)

      # Ensure Home Manager session vars are loaded from the active HM profile.
      # Unset guard set by ~/.nix-profile hm-session-vars and source the real one.
      if [ -f "$HOME/.local/state/nix/profiles/home-manager/home-path/etc/profile.d/hm-session-vars.sh" ]; then
        unset __HM_SESS_VARS_SOURCED
        . "$HOME/.local/state/nix/profiles/home-manager/home-path/etc/profile.d/hm-session-vars.sh"
      fi

      # zplug setup and plugins
      export ZPLUG_HOME="$HOME/.zplug"
      source ${pkgs.zplug}/share/zplug/init.zsh
      zplug "zsh-users/zsh-autosuggestions"
      zplug "zsh-users/zsh-syntax-highlighting"
      # Lightweight, widely-used completion set (fast, no heavy widgets)
      zplug "zsh-users/zsh-completions", use:"src"
      # zplug "marlonrichert/zsh-autocomplete"
      zplug "jeffreytse/zsh-vi-mode"
      if ! zplug check; then
        zplug install
      fi
      zplug load
      # Auto-set JAVA_HOME based on asdf current java
      if [ -f "$HOME/.asdf/plugins/java/set-java-home.zsh" ]; then
        . "$HOME/.asdf/plugins/java/set-java-home.zsh"
      fi
      # --------------------------
      # 1) COMPINIT + CACHE
      # --------------------------
      # Ensure third-party completions are in fpath before compinit
      fpath=("$ZPLUG_HOME/repos/zsh-users/zsh-completions/src" $fpath)
      autoload -Uz compinit
      # Use a directory in .cache or as you prefer
      compinit -d ''${XDG_CACHE_HOME:-''${HOME}/.cache}/zsh/zcompdump-''${ZSH_VERSION}

      # Completion behavior: always list, never ask
      # Prevent the prompt: "do you wish to see all ...?"
      setopt AUTO_LIST      # fallback: list on ambiguous completions
      unsetopt LIST_BEEP
      unsetopt LIST_ASK     # stop zsh from asking before showing long lists
      LISTMAX=0             # never trigger the confirmation threshold
      zstyle ":completion:*" list-prompt ""

      # --------------------------
      # 2) Tools initialization
      # --------------------------
      eval "$(zoxide init zsh)"
      eval "$(atuin init zsh)"
      eval "$(starship init zsh)"

      # --------------------------
      # 3) Final cleanup
      # --------------------------
      # Clear gives you that "fresh" feeling,
      # but if you prefer speed, you can comment it out.
      clear

      # --------------------------
      # 4) Homebrew PATH (login and non-login shells)
      # --------------------------
      # In login shells, extend PATH and load Homebrew

      # Determine Homebrew path and load its environment (ARM and Intel macOS)
      if command -v brew >/dev/null 2>&1; then
        eval "$(brew shellenv)"
      else
        # Fallbacks for common locations
        for candidate in /opt/homebrew/bin/brew /usr/local/bin/brew; do
          if [ -x "$candidate" ]; then
            eval "$($candidate shellenv)"
            break
          fi
        done
      fi

    # Multiplexer autostart removed; use plain Zsh in Ghostty
    # Initialize asdf
    . ${pkgs.asdf-vm}/share/asdf-vm/asdf.sh

    # Unset c/c++ related dependencies to avoid using nix's.
      unset CC
      unset CXX
      unset AR
      unset RANLIB
      unset STRIP
      unset LD
      unset AS
      
    '';
  };

  # We avoid overriding .zshenv to prevent conflicts with the zsh module.
  # The initContent above ensures correct session vars and zsh initialization.
}
