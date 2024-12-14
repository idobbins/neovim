#!/bin/bash

set -euo pipefail

# Check if running on macOS
if [ "$(uname)" != "Darwin" ]; then
    echo "Error: This script is only for macOS systems"
    exit 1
fi

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

echo "Starting macOS system bootstrap..."

# Check for Xcode Command Line Tools
if ! command_exists gcc; then
    echo "Installing Xcode Command Line Tools..."
    sudo touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
    
    PROD=$(sudo softwareupdate -l | grep "\*.*Command Line" | tail -n 1 | sed 's/^[^C]* //')
    
    sudo softwareupdate -i "$PROD" --verbose
    sudo rm /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
    
    if ! command_exists gcc; then
        echo "Error: Xcode Command Line Tools installation failed."
        exit 1
    fi
fi

# Install Nix if not already installed
if ! command_exists nix; then
    echo "Installing Nix..."
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --determinate
    
    # Source nix
    . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
fi

# Set up directories and clone repository
REPO_URL="https://github.com/idobbins/env.git"
TARGET_DIR="$HOME/.config/env"
CONFIG_DIR="$HOME/.config"

# Create .config directory if it doesn't exist
mkdir -p "$CONFIG_DIR"

# Clone or update repository
if [ ! -d "$TARGET_DIR" ]; then
    echo "Cloning configuration repository..."
    git clone "$REPO_URL" "$TARGET_DIR"
else
    echo "Configuration repository already exists, updating..."
    cd "$TARGET_DIR"
    git pull
fi

cd "$TARGET_DIR"

# Create symlinks
echo "Creating symlinks..."

# Symlink flake.nix to home directory
ln -sfn "$TARGET_DIR/macos-flake.nix" "$HOME/.flake.nix"

# Build and activate configuration
echo "Building and activating configuration..."
nix build
home-manager switch --flake .#idobbins

echo "Bootstrap complete! Your macOS environment has been configured."
echo "Configuration files are at: $TARGET_DIR"
echo "Please restart your terminal for all changes to take effect."
