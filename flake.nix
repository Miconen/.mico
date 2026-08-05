{
  description = "miso's declarative user environment (Arch laptop + WSL)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Prebuilt nix-index database, so `comma` and `nix-locate` work immediately
    # instead of after a long local index build. Costs a few hundred MB, refreshed
    # upstream weekly.
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      nix-index-database,
      ...
    }:
    let
      system = "x86_64-linux";
      username = "miso";

      # Single source of truth for where this repo is checked out. Consumed by
      # the nvim out-of-store symlink, the `hms` alias and the editing aliases,
      # so relocating the repo is a one-line change here.
      repoPath = "/home/${username}/.mico";

      # allowUnfree is set here rather than via `nixpkgs.config` in a module,
      # because home-manager refuses `nixpkgs.*` options when `pkgs` is passed
      # explicitly to homeManagerConfiguration.
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

      # hostName is passed through so common.nix can build the `hms` alias
      # itself, instead of each host file repeating it.
      mkHome =
        hostName: hostModule:
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [
            # `homeModules`, not `hmModules` - the latter is deprecated upstream
            # and emits a rename warning.
            nix-index-database.homeModules.nix-index
            ./home/common.nix
            hostModule
          ];
          extraSpecialArgs = { inherit username hostName repoPath; };
        };

      configs = {
        arch = mkHome "arch" ./hosts/arch.nix;
        wsl = mkHome "wsl" ./hosts/wsl.nix;
      };
    in
    {
      homeConfigurations = configs;

      # Makes `nix flake check` build both hosts. Without this it checks almost
      # nothing, because homeConfigurations is not a standard flake output.
      checks.${system} = builtins.mapAttrs (_name: cfg: cfg.activationPackage) configs;

      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          # nix
          nixfmt
          statix
          deadnix

          # shell - bootstrap.sh and ci/lint.sh are non-trivial now.
          # shellcheck-minimal rather than shellcheck: same binary, much smaller
          # closure, since the full attribute pulls in the wrapper and docs.
          shellcheck-minimal
          shfmt

          # CI workflow YAML
          actionlint

          # ci/zellij-check.sh starts a real session to validate the config and
          # layout, because `zellij setup --check` is too permissive to catch
          # an empty new_tab_template.
          zellij

          # neovim config lives in .config/nvim now
          stylua
          selene
        ];
      };

      formatter.${system} = pkgs.nixfmt;
    };
}
