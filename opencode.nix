{ pkgs, lib, ... }:

{
  # Install GitHub CLI and tools for Copilot authentication and OpenCode installation
  home.packages = [
    pkgs.gh
    pkgs.curl
    pkgs.gawk
    pkgs.gnutar
    pkgs.gzip
    pkgs.coreutils
    pkgs.unzip
  ];

  # Setup GitHub CLI
  programs.gh = {
    settings = {
      version = "1";
    };
  };

  # Add OpenCode to PATH for all shells
  home.sessionPath = [
    "$HOME/.opencode/bin"
  ];

  # Create OpenCode installation script for manual use
  home.file."bin/install-opencode" = {
    text = ''
      #!/usr/bin/env bash
      set -e

      OPENCODE_DIR="$HOME/.opencode"
      OPENCODE_BIN="$OPENCODE_DIR/bin/opencode"

      # Create required cache directories
      mkdir -p "$HOME/.cache/nvim/opencode"

      # Set PATH to include all required tools
      export PATH="${pkgs.unzip}/bin:${pkgs.curl}/bin:${pkgs.gawk}/bin:${pkgs.gnutar}/bin:${pkgs.gzip}/bin:${pkgs.coreutils}/bin:${pkgs.gh}/bin:$PATH"

      # Check if OpenCode is already installed and working
      if [ -f "$OPENCODE_BIN" ] && "$OPENCODE_BIN" --version &>/dev/null; then
        INSTALLED_VERSION=$("$OPENCODE_BIN" --version 2>/dev/null | head -n1 || echo "unknown")
        echo "✅ OpenCode already installed: $INSTALLED_VERSION"
        read -p "Do you want to reinstall/update? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
          echo "Skipping OpenCode installation"
        else
          echo "🚀 Reinstalling OpenCode..."
          curl -fsSL https://opencode.ai/install | bash 
          if [ -f "$OPENCODE_BIN" ]; then
            INSTALLED_VERSION=$("$OPENCODE_BIN" --version 2>/dev/null | head -n1 || echo "unknown")
            echo "✅ OpenCode v$INSTALLED_VERSION installed successfully!"
          else
            echo "❌ OpenCode installation failed"
            exit 1
          fi
        fi
      else
        echo "🚀 Installing latest OpenCode..."
        curl -fsSL https://opencode.ai/install | bash 
        if [ -f "$OPENCODE_BIN" ]; then
          INSTALLED_VERSION=$("$OPENCODE_BIN" --version 2>/dev/null | head -n1 || echo "unknown")
          echo "✅ OpenCode v$INSTALLED_VERSION installed successfully!"
        else
          echo "❌ OpenCode installation failed"
          exit 1
        fi
      fi

      # Install GitHub Copilot extension if not present
      if ! gh extension list | grep -q "github/gh-copilot"; then
        echo "📦 Installing GitHub Copilot extension..."
        gh extension install github/gh-copilot
        echo "✅ GitHub Copilot extension installed!"
      else
        echo "✅ GitHub Copilot extension already installed"
      fi
      echo ""
      echo "🎉 OpenCode setup complete!"
      echo "Usage: opencode | opencode-config | gh auth status"
    '';
    executable = true;
  };

  # Auto-install OpenCode on home-manager activation
  home.activation.installOpenCode = lib.hm.dag.entryAfter ["linkGeneration"] ''
    echo "🔧 Setting up OpenCode..."

    OPENCODE_DIR="$HOME/.opencode"
    OPENCODE_BIN="$OPENCODE_DIR/bin/opencode"

    # Create required cache directories
    mkdir -p "$HOME/.cache/nvim/opencode"

    # Set PATH to include all required tools
    export PATH="${pkgs.unzip}/bin:${pkgs.curl}/bin:${pkgs.gawk}/bin:${pkgs.gnutar}/bin:${pkgs.gzip}/bin:${pkgs.coreutils}/bin:${pkgs.gh}/bin:$PATH"

    # Check if OpenCode is already installed and working
    if [ -f "$OPENCODE_BIN" ] && "$OPENCODE_BIN" --version &>/dev/null; then
      INSTALLED_VERSION=$("$OPENCODE_BIN" --version 2>/dev/null | head -n1 || echo "unknown")
      echo "✅ OpenCode already installed: $INSTALLED_VERSION"
    else
      echo "🚀 Installing latest OpenCode..."
      curl -fsSL https://opencode.ai/install | bash 

      if [ -f "$OPENCODE_BIN" ]; then
        INSTALLED_VERSION=$("$OPENCODE_BIN" --version 2>/dev/null | head -n1 || echo "unknown")
        echo "✅ OpenCode v$INSTALLED_VERSION installed successfully!"
      else
        echo "❌ OpenCode installation failed"
      fi
    fi

    # Install GitHub Copilot extension if not present
    if ! gh extension list | grep -q "github/gh-copilot"; then
      echo "📦 Installing GitHub Copilot extension..."
      gh extension install github/gh-copilot
      echo "✅ GitHub Copilot extension installed!"
    else
      echo "✅ GitHub Copilot extension already installed"
    fi
    echo ""
    echo "🎉 OpenCode setup complete!"
    echo "Usage: opencode | opencode-config | gh auth status"
  '';

  # Create OpenCode configuration file
  home.file.".config/opencode/opencode.json" = {
    text = builtins.toJSON {
      "$schema" = "https://opencode.ai/config.json";
      theme = "system";
      model = "opencode/grok-code";
      autoupdate = true;
      agent = {
        code-reviewer = {
          description = "Reviews code for best practices and potential issues as the Gentleman";
          prompt = "You are a senior software engineer who is highly advanced in software clean architecture and scalable systems. You are also an expert in security best practices and performance optimization. You will review the provided code and suggest improvements, optimizations, and identify potential issues. Provide your feedback in a constructive and professional manner.";
          model = "opencode/grok-code";
          tools = {
            write = true;
            edit = true;
          };
        };
      };
    };
  };

  # Add aliases for all configured shells
  programs.fish.shellAliases.opencode-config = "nvim ~/.config/opencode/opencode.json";
  programs.zsh.shellAliases.opencode-config = "nvim ~/.config/opencode/opencode.json";
  programs.nushell.shellAliases.opencode-config = "nvim ~/.config/opencode/opencode.json";
}
