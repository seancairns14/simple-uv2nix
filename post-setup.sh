#!/bin/bash

# Ensure the script fails if any command fails
set -e

# Function to install pip packages (Git URLs or package names)
install_package() {
  local package=$1
  echo "Installing package: $package"
  nix run nixpkgs#uv -- pip install "$package"
}

# Install each argument as a pip package
if [ "$#" -gt 0 ]; then
  for package in "$@"; do
    install_package "$package"
  done
else
  echo "No packages provided. Skipping package installation."
fi

# Freeze requirements
echo "Freezing requirements..."
nix run nixpkgs#uv -- pip freeze > requirements.txt

# Install pdm and update pyproject.toml
echo "Installing pdm and initializing project..."
nix run nixpkgs#uv -- pip install -U pdm
nix run nixpkgs#uv -- run pdm import requirements.txt 

# Lock dependencies
echo "Locking dependencies..."
nix run nixpkgs#uv lock

echo "Post setup completed successfully."
