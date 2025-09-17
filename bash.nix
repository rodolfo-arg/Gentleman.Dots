{ pkgs, lib, ... }:
{
  programs.bash = {
    enable = true;
    enableCompletion = true;

    # Ensure login shells also get sane environment even if system files are stale
    profileExtra = ''
      # Prefer Home Manager session variables from home-path when available
      if [ -f "$HOME/.local/state/nix/profiles/home-manager/home-path/etc/profile.d/hm-session-vars.sh" ]; then
        # Make sourcing tolerant to `set -u` (nounset)
        _HM_NOUNSET_WAS_ON=
        if (set -o | grep -q 'nounset[[:space:]]*on'); then _HM_NOUNSET_WAS_ON=1; set +u; fi
        unset __HM_SESS_VARS_SOURCED
        . "$HOME/.local/state/nix/profiles/home-manager/home-path/etc/profile.d/hm-session-vars.sh"
        if [ -n "''${_HM_NOUNSET_WAS_ON-}" ]; then set -u; unset _HM_NOUNSET_WAS_ON; fi
      fi
      # PATH safety
      export PATH="$HOME/.local/state/nix/profiles/home-manager/home-path/bin:$HOME/.nix-profile/bin:$PATH"
    '';

    # Interactive shell setup for Bash
    initExtra = ''
      # Ensure Home Manager session variables are loaded (tolerate `set -u`)
      if [ -f "$HOME/.local/state/nix/profiles/home-manager/home-path/etc/profile.d/hm-session-vars.sh" ]; then
        _HM_NOUNSET_WAS_ON=
        if (set -o | grep -q 'nounset[[:space:]]*on'); then _HM_NOUNSET_WAS_ON=1; set +u; fi
        unset __HM_SESS_VARS_SOURCED
        . "$HOME/.local/state/nix/profiles/home-manager/home-path/etc/profile.d/hm-session-vars.sh"
        if [ -n "''${_HM_NOUNSET_WAS_ON-}" ]; then set -u; unset _HM_NOUNSET_WAS_ON; fi
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

      ${lib.optionalString pkgs.stdenv.isLinux ''
      # Ghostty wrapper for buggy EGL on some Linux VMs
      alias ghostty='GSK_RENDERER=cairo LIBGL_ALWAYS_SOFTWARE=1 ${pkgs.ghostty}/bin/ghostty'
      # Neovide: prefer software GL and X11 on Linux VMs
      alias neovide='LIBGL_ALWAYS_SOFTWARE=1 MESA_LOADER_DRIVER_OVERRIDE=llvmpipe WINIT_UNIX_BACKEND=x11 ${pkgs.neovide}/bin/neovide'
      ''}
    '';
  };
}
