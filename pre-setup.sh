#!/bin/bash

# Load environment variables from .env file (if it exists)
if [ -f .env ]; then
  export $(cat .env | xargs)
fi

# Check if an argument is provided in the format python=3.x
if [[ "$1" =~ ^python=([0-9]+\.[0-9]+)$ ]]; then
  # Extract the version number from the argument
  PYTHON_VERSION="${BASH_REMATCH[1]}"
else
  # If the format is incorrect, display an error and exit
  echo "Usage: $0 python=3.x"
  exit 1
fi

# Step 1: Set Python version to the value of PYTHON_VERSION
echo "$PYTHON_VERSION" > .python-version

# Step 2: Update pyproject.toml to require the specified Python version
sed -i "s/python = \"[^\"]*\"/python = \">=$PYTHON_VERSION\"/" pyproject.toml

# Step 3: Run nix to lock uv
nix run nixpkgs#uv lock

# Step 4: Stage the modified files for commit
git add flake.nix uv.lock pyproject.toml .python-version

# Step 5: Pass the environment variable and run nix develop
nix develop --ignore-environment
