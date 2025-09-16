{ pkgs, lib, ... }:
{
  # Configure Neovide via its config file on macOS
  home.file = lib.mkIf pkgs.stdenv.isDarwin {
    "Library/Application Support/neovide/config.toml" = {
      text = ''
        [window]
        frame = "none"
      '';
      force = true;
    };
  };
}

