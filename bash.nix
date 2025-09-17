{ pkgs, lib, ... }:
{
  programs.bash = {
    enable = true;
    enableCompletion = true;

    # Ensure login shells also get sane environment even if system files are stale
    profileExtra = ''
      # Prefer Home Manager session variables from home-path when available
      if [ -f "$HOME/.local/state/nix/profiles/home-manager/home-path/etc/profile.d/hm-session-vars.sh" ]; then
        unset __HM_SESS_VARS_SOURCED
        . "$HOME/.local/state/nix/profiles/home-manager/home-path/etc/profile.d/hm-session-vars.sh"
      fi
      # PATH safety
      export PATH="$HOME/.local/state/nix/profiles/home-manager/home-path/bin:$HOME/.nix-profile/bin:$PATH"
    '';

    # Interactive shell setup for Bash
    initExtra = ''
      # Ensure Home Manager session variables are loaded
      if [ -f "$HOME/.local/state/nix/profiles/home-manager/home-path/etc/profile.d/hm-session-vars.sh" ]; then
        unset __HM_SESS_VARS_SOURCED
        . "$HOME/.local/state/nix/profiles/home-manager/home-path/etc/profile.d/hm-session-vars.sh"
      fi

      # Prepend Home Manager profile bin and user nix-profile bin to PATH
      export PATH="$HOME/.local/state/nix/profiles/home-manager/home-path/bin:$HOME/.nix-profile/bin:$PATH"

      # Completions/Tools
      # Carapace completions for bash (safe if not installed)
      if command -v carapace >/dev/null 2>&1; then
        source <(carapace _carapace)
      fi

      # Initialize common tools
      command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init bash)"
      command -v atuin >/dev/null 2>&1 && eval "$(atuin init bash)"
      command -v starship >/dev/null 2>&1 && eval "$(starship init bash)"

      # Helpful aliases (aligned with zsh config)
      alias o=oil
      alias of=oil-float
      alias 'oo=oil .'
      alias oz=oil-zed
    '';
  };
}
