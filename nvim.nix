{ ... }:
{
  # Declaratively manage Neovim config via Home Manager
  home.file.".config/nvim" = {
    source = ./nvim;
    recursive = true;
  };
}
