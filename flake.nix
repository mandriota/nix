{
  description = "Example nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin = {
      url = "github:LnL7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    { self, fenix, nix-darwin, nixpkgs, home-manager, nix-homebrew }@inputs:
    let
      # config shared between all systems
      commonConfig = import ./hosts/common.nix;

      darwinConfig = import ./hosts/darwin.nix;

      nixosConfig = import ./hosts/nixos.nix;
    in {
      # $ darwin-rebuild build --flake .#spectral
      darwinConfigurations.spectral = nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        specialArgs = inputs;
        modules = [
          commonConfig
          darwinConfig
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
          }
          nix-homebrew.darwinModules.nix-homebrew
          {
            nix-homebrew = {
              enable = true;
              enableRosetta = true;
              user = "mark";
            };
          }

          ({ pkgs, ... }: {
            environment.variables = { LIBRARY_PATH = "${pkgs.libiconv}/lib"; };
          })
        ];
      };

      nixosConfigurations.kururu = nixpkgs.lib.nixosSystem {
        specialArgs = inputs;
        modules = [
          commonConfig
          nixosConfig
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.ku = import ./home.nix;
          }
        ];
      };
    };
}
