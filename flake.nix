{
  description = "uv2nix devshell";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pyproject-nix = {
      url = "github:pyproject-nix/pyproject.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    uv2nix = {
      url = "github:pyproject-nix/uv2nix";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pyproject-build-systems = {
      url = "github:pyproject-nix/build-system-pkgs";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.uv2nix.follows = "uv2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      nixpkgs,
      flake-utils,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        workspaceRoot = ./.;
        venvName = "venv";
        
        versionFilePath = ./.python-version;
        # Read Python version from the .python-version file
        versionContents = builtins.readFile versionFilePath;
         pythonVersion = builtins.substring 0 (builtins.stringLength versionContents - 1) versionContents;
        # Use lib.replaceStrings to format the version (replace . with "")
        pythonVersionFormatted = if pythonVersion != "" then
          "python" + (nixpkgs.lib.replaceStrings [ "." ] [ "" ] pythonVersion)
        else
          "python312";  # Default if not set in .env or environment

        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

        python = pkgs.${pythonVersionFormatted};

        workspace = inputs.uv2nix.lib.workspace.loadWorkspace { workspaceRoot = workspaceRoot; };
        overlay = workspace.mkPyprojectOverlay {
          sourcePreference = "wheel";
        };
        baseSet = pkgs.callPackage inputs.pyproject-nix.build.packages {
          inherit python;
        };
        pythonSet = baseSet.overrideScope (
          pkgs.lib.composeManyExtensions [
            inputs.pyproject-build-systems.overlays.default
            overlay
          ]
        );
        venv = pythonSet.mkVirtualEnv "${venvName}" workspace.deps.default;
      in
      {
        devShells.default = pkgs.mkShell {
          packages = [
            pkgs.uv
            venv
          ];
          shellHook = ''
            echo "Using Python version: ${pythonVersion}"
          '';
        };
      }
    );
}
