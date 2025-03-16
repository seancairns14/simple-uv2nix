#!/bin/bash

# Check if PYTHON_VERSION is set, otherwise default to 3.12
PYTHON_VERSION="${PYTHON_VERSION:-3.12}"

# Step 1: Set Python version to the value of PYTHON_VERSION
echo "$PYTHON_VERSION" > .python-version

# Step 2: Update pyproject.toml to require the specified Python version
sed -i "s/python = \"[^\"]*\"/python = \">=$PYTHON_VERSION\"/" pyproject.toml

# Step 3: Run nix to lock uv
nix run nixpkgs#uv lock

# Step 4: Stage the modified files for commit
git add flake.nix uv.lock pyproject.toml .python-version

# Step 5: Enter the nix develop environment
nix develop --ignore-environment
