{ ... }:
{
  # Configure Neovide via its standard config file path
  # https://neovide.dev/config-file.html
  home.file = {
    ".config/neovide/config.toml" = {
      text = ''
        [window]
        frame = "none"
      '';
      force = true;
    };
  };
}
