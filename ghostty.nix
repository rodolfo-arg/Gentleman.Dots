{ ... }:
{
  # Declaratively manage Ghostty config via Home Manager, avoiding activation copy scripts
  home.file.".config/ghostty" = {
    source = ./ghostty;
    recursive = true;
  };
}
