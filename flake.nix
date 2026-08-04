{
  description = "miso's declarative user environment (Arch laptop + WSL)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, home-manager, ... }:
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
          nixfmt
          statix
          deadnix
        ];
      };

      formatter.${system} = pkgs.nixfmt;
    };
}
