{
  description = "Gentleman: Single config for all systems in one go";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";  # Main Nixpkgs for stable packages
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";  # Unstable Nixpkgs for latest packages
    home-manager = {
      url = "github:nix-community/home-manager";  # Home Manager repository for user configs
      inputs.nixpkgs.follows = "nixpkgs";  # Follow nixpkgs input for consistency
    };
    flake-utils.url = "github:numtide/flake-utils";  # Flake utilities for multi-system support
    snacks-nvim = {
      url = "github:folke/snacks.nvim";  # Snacks plugin for Neovim
      flake = false;
    };
  };

  outputs = { nixpkgs, nixpkgs-unstable, home-manager, flake-utils, ... }:
    let
      # Support macOS systems only
      supportedSystems = [ "x86_64-darwin" "aarch64-darwin" ];

      # Common modules shared across configurations
      commonModules = [
        ./nushell.nix  # Nushell configuration
        ./ghostty.nix  # Ghostty configuration
        ./zed.nix  # Zed configuration
        ./television.nix  # Television configuration
        ./wezterm.nix  # WezTerm configuration
        # ./zellij.nix  # Zellij configuration (commented out)
        ./tmux.nix  # Tmux configuration
        ./fish.nix  # Fish shell configuration
        ./starship.nix  # Starship prompt configuration
        ./nvim.nix  # Neovim configuration
        ./zsh.nix  # Zsh configuration
        ./oil-scripts.nix  # Oil.nvim scripts configuration
        ./opencode.nix  # OpenCode AI assistant configuration
        ./claude.nix  # Claude Code CLI configuration
      ];

      # Function to create home configuration for a specific system
      mkHomeConfiguration = system: { username ? "rodolfo", homeDirectory ? "/Users/rodolfo" }:
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };

          unstablePkgs = import nixpkgs-unstable {
            inherit system;
            config.allowUnfree = true;
          };
        in
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;

          # Pass extraSpecialArgs to make unstablePkgs available in modules
          extraSpecialArgs = {
            inherit unstablePkgs;
          };

          modules = commonModules ++ [
            {
              # Personal data (now configurable)
              home.username = username;
              home.homeDirectory = homeDirectory;
              home.stateVersion = "24.11";  # State version

              # Base packages that should be available everywhere
              home.packages = with pkgs; [
                # Terminals
                tmux fish zsh nushell
                # Development
                volta carapace zoxide atuin jq bash starship fzf nodejs bun cargo go nil android-tools
                # Compilers/Utilities
                clang fd ripgrep coreutils unzip bat lazygit yazi television asdf-vm
                # Fonts
                nerd-fonts.iosevka-term
              ] ++ [ unstablePkgs.nixd ];

              home.sessionVariables = {
                # Set environment variables
                ANDROID_HOME = "$HOME/Library/Android/sdk";
                ANDROID_NDK_HOME = "$HOME/Library/Android/sdk/ndk/27.0.12077973";
              };

              home.sessionPath = [
                "$HOME/.asdf/shims"
                "$HOME/.asdf/bin"
                "$HOME/.pub-cache/bin"
                "${pkgs.android-tools}/bin"
              ];
              # Enable programs explicitly (critical for binaries to appear)
              # All program enables are centralized here
              programs.neovim.enable = true;
              programs.fish.enable = true;
              programs.nushell.enable = true;
              programs.starship.enable = true;
              programs.zsh.enable = true;
              programs.git.enable = true;
              programs.gh.enable = true;  # GitHub CLI
              programs.home-manager.enable = true;
              # Note: tmux is configured via home.file in tmux.nix, not programs.tmux

              # Allow unfree packages
              nixpkgs.config.allowUnfree = true;
            }
          ];
        };
    in
    {
      # Home Manager configurations for each system
      homeConfigurations = {
        # macOS system configurations
        "gentleman-macos-intel" = mkHomeConfiguration "x86_64-darwin" {};
        "gentleman-macos-arm" = mkHomeConfiguration "aarch64-darwin" {};

        # Default to Apple Silicon
        "gentleman" = mkHomeConfiguration "aarch64-darwin" {};
      };

      # Development shell for Nix development
      devShells = flake-utils.lib.eachSystem supportedSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
        in {
          default = pkgs.mkShell {
            buildInputs = [ pkgs.nixd pkgs.nil ];
            shellHook = "echo 'Nix development shell ready'";
          };
        }
      );
    };
}
