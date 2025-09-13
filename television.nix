{ ... }:
{
  # Declaratively manage Television config via Home Manager
  home.file.".config/television" = {
    source = ./television;
    recursive = true;
  };
}
