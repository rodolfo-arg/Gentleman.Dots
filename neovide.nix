{ ... }:
{
  # Configure Neovide via its standard config file path
  # https://neovide.dev/config-file.html
  home.file = {
    ".config/neovide/config.toml" = {
      text = ''
        frame = "none"
      '';
      force = true;
    };
  };
}
