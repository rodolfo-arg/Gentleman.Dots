{ ... }:
{
  # Declaratively manage Zed config via Home Manager
  home.file.".config/zed" = {
    source = ./zed;
    recursive = true;
    force = true;
  };
}
