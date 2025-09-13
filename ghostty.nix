{ ... }:
{
  # Declaratively manage Ghostty config via Home Manager
  home.file.".config/ghostty" = {
    source = ./ghostty;
    recursive = true;
    force = true;
  };
}
