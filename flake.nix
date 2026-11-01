{
  description = "miso's declarative user environment (Arch laptop + WSL)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Prebuilt index for `comma` / `nix-locate`, avoiding a long local build.
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

      repoPath = "/home/${username}/.mico";

      # Set here, not via `nixpkgs.config`: home-manager rejects `nixpkgs.*`
      # options when `pkgs` is passed explicitly.
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

      mkHome =
        hostName: hostModule:
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [
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

      # homeConfigurations isn't a standard output, so `nix flake check` would
      # otherwise build nothing.
      checks.${system} = builtins.mapAttrs (_name: cfg: cfg.activationPackage) configs;

      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          # nix
          nixfmt
          statix
          deadnix

          # shell
          shellcheck-minimal
          shfmt

          # CI
          actionlint
          # ci/zellij-check.sh starts a real session; `zellij setup --check` is too lax.
          zellij

          # lua
          stylua
          selene
        ];
      };

      formatter.${system} = pkgs.nixfmt;
    };
}
