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
      # Support macOS and Linux systems
      supportedSystems = [ "x86_64-darwin" "aarch64-darwin" "x86_64-linux" "aarch64-linux" ];

      lib = nixpkgs.lib;

      # Common modules shared across configurations
      commonModules = [
        ./ghostty.nix  # Ghostty configuration
        ./television.nix  # Television configuration
        ./starship.nix  # Starship prompt configuration
        ./nvim.nix  # Neovim configuration
        ./neovide.nix  # Neovide GUI configuration
        ./bash.nix  # Bash configuration
        ./zsh.nix  # Zsh configuration
        ./oil-scripts.nix  # Oil.nvim scripts configuration
        ./opencode.nix  # OpenCode AI assistant configuration
      ];

      # Function to create home configuration for a specific system
      mkHomeConfiguration = system: { username ? "rodolfo", homeDirectory ? null }:
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };

          unstablePkgs = import nixpkgs-unstable {
            inherit system;
            config.allowUnfree = true;
          };
          # Resolve defaults per-platform
          isDarwin = pkgs.stdenv.isDarwin;
          isLinux = pkgs.stdenv.isLinux;
          effectiveHome = if homeDirectory != null then homeDirectory else if isDarwin then "/Users/${username}" else "/home/${username}";

          androidHome = if isDarwin then "${effectiveHome}/Library/Android/sdk" else "${effectiveHome}/Android/Sdk";
          ndkVersion = "28.1.13356709";
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
              home.homeDirectory = effectiveHome;
              home.stateVersion = "24.11";  # State version

              # Base packages that should be available everywhere
              home.packages = with pkgs; [
                # Terminal
                zsh
                # Development
                volta carapace zoxide atuin jq bash starship fzf nodejs bun cargo go nil
                # Compilers/Utilities
                clang fd ripgrep coreutils unzip bat lazygit yazi asdf-vm
                # Fonts
                nerd-fonts.iosevka-term
              ]
              # Extra helpers per-platform
              ++ lib.optionals isLinux [ xclip wl-clipboard ghostty ]
              ++ [ unstablePkgs.nixd ];

              home.sessionVariables = {
                # Set environment variables
                ANDROID_HOME = androidHome;
                ANDROID_NDK_HOME = "${androidHome}/ndk/${ndkVersion}";
                ANDROID_SDK_ROOT = androidHome;
              };

              home.sessionPath = [
                "$HOME/.asdf/shims"
                "$HOME/.asdf/bin"
                "$HOME/.pub-cache/bin"
                "${androidHome}/cmdline-tools/latest/bin"
                "${androidHome}/platform-tools"
              ] ++ lib.optionals isDarwin [
                "/opt/homebrew/bin"
                "/opt/homebrew/sbin"
              ];
              # Enable programs explicitly (critical for binaries to appear)
              # All program enables are centralized here
              programs.neovim.enable = true;
              programs.starship.enable = true;
              programs.zsh.enable = true;
              programs.git.enable = true;
              programs.gh.enable = true;  # GitHub CLI
              programs.home-manager.enable = true;
              # Optional: keep flake inputs fresh on every switch (best-effort)
              home.activation.updateFlakeInputs = home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
                REPO_DIR="$HOME/Gentleman.Dots"
                if [ -d "$REPO_DIR/.git" ]; then
                  echo "[flake] Updating inputs in $REPO_DIR"
                  # Ensure git is available to nix while updating inputs
                  export PATH="${pkgs.git}/bin:$PATH"
                  if command -v nix >/dev/null 2>&1 && command -v git >/dev/null 2>&1; then
                    (cd "$REPO_DIR" && nix flake update) || true
                  else
                    echo "[flake] Skipping update (nix or git not available)"
                  fi
                fi
              '';
              # Tmux and other terminals are intentionally not managed; only Ghostty + Zsh

              # Allow unfree packages
              nixpkgs.config.allowUnfree = true;

              # Tweak Nix user settings
              nix.settings = {
                # Avoid small default buffer warnings during large downloads
                download-buffer-size = 134217728; # 128 MiB
              };

              # Required when using nix.settings via Home Manager
              nix.package = pkgs.nix;
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

        # Linux system configurations
        "gentleman-linux-intel" = mkHomeConfiguration "x86_64-linux" {};
        "gentleman-linux-arm" = mkHomeConfiguration "aarch64-linux" {};

        # Default stays Apple Silicon; installer picks the right one per-OS
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
