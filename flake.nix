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

      # allowUnfree is set here rather than via `nixpkgs.config` in a module,
      # because home-manager refuses `nixpkgs.*` options when `pkgs` is passed
      # explicitly to homeManagerConfiguration.
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

      mkHome =
        hostModule:
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [
            ./home/common.nix
            hostModule
          ];
          extraSpecialArgs = { inherit username; };
        };
    in
    {
      homeConfigurations = {
        arch = mkHome ./hosts/arch.nix;
        wsl = mkHome ./hosts/wsl.nix;
      };

      formatter.${system} = pkgs.nixfmt;
    };
}
