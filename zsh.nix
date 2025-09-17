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
      zplug "marlonrichert/zsh-autocomplete"
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
      autoload -Uz compinit
      # Use a directory in .cache or as you prefer
      compinit -d ''${XDG_CACHE_HOME:-''${HOME}/.cache}/zsh/zcompdump-''${ZSH_VERSION}

      # --------------------------
      # 2) FZF
      # --------------------------
      export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git"
      export FZF_DEFAULT_T_COMMAND="$FZF_DEFAULT_COMMAND"
      export FZF_ALT_COMMAND="fd --type=d --hidden --strip-cwd-prefix --exclude .git"

      alias fzfbat='fzf --preview="bat --theme=gruvbox-dark --color=always {}"'
      alias fzfnvim='nvim $(fzf --preview="bat --theme=gruvbox-dark --color=always {})"'

      # If you really need this eval, leave it:
      # eval "$(fzf --zsh)"

      # --------------------------
      # 3) Carapace
      # --------------------------
      export CARAPACE_BRIDGES='zsh,bash,inshellisense'
      zstyle ':completion:*' format $'\e[2;37mCompleting %d\e[m'
      source <(carapace _carapace)

      # --------------------------
      # 4) Tools initialization
      # --------------------------
      eval "$(zoxide init zsh)"
      eval "$(atuin init zsh)"
      eval "$(starship init zsh)"

      ya_zed() {
        tmp=$(mktemp -t "yazi-chooser.XXXXXXXXXX")
        yazi --chooser-file "$tmp" "$@"

        if [[ -s "$tmp" ]]; then
          opened_file=$(head -n 1 -- "$tmp")
          if [[ -n "$opened_file" ]]; then
            if [[ -d "$opened_file" ]]; then
              # Es una carpeta, la agregamos al workspace
              zed --add "$opened_file"
            else
              # Es un archivo, lo abrimos normalmente
              zed --add "$opened_file"
            fi
          fi
        fi

        rm -f -- "$tmp"
      }

      # --------------------------
      # 5) Final cleanup
      # --------------------------
      # Clear gives you that "fresh" feeling,
      # but if you prefer speed, you can comment it out.
      clear

      # --------------------------
      # 6) Homebrew PATH (login and non-login shells)
      # --------------------------
      # In login shells, extend PATH and load Homebrew
      if [[ -o login ]]; then
        export PATH="$HOME/.opencode/bin:$HOME/.cargo/bin:$HOME/.volta/bin:$HOME/.bun/bin:$HOME/.nix-profile/bin:/nix/var/nix/profiles/default/bin:$PATH:/usr/local/bin:$HOME/.config:$HOME/.cargo/bin:/usr/local/lib/*"
      fi

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

    # Bash completions also work in Zsh, so source them
    . ${pkgs.asdf-vm}/share/asdf-vm/completions/asdf.bash

      # Aliases ensured here so they are present regardless of HM alias injection
      alias -- o=oil
      alias -- of=oil-float
      alias -- oo='oil .'
      alias -- oz=oil-zed
      alias -- opencode-config='nvim ~/.config/opencode/opencode.json'

      ${lib.optionalString pkgs.stdenv.isLinux ''
      # Ghostty wrapper for buggy EGL on some Linux VMs
      alias ghostty='GSK_RENDERER=cairo LIBGL_ALWAYS_SOFTWARE=1 ${pkgs.ghostty}/bin/ghostty'
      # Neovide: prefer software GL and X11 on Linux VMs
      alias neovide='LIBGL_ALWAYS_SOFTWARE=1 MESA_LOADER_DRIVER_OVERRIDE=llvmpipe WINIT_UNIX_BACKEND=x11 ${pkgs.neovide}/bin/neovide'
      ''}
    '';
  };

  # We avoid overriding .zshenv to prevent conflicts with the zsh module.
  # The initContent above ensures correct session vars and zsh initialization.
}
