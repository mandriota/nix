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
      configuration = { pkgs, lib, ... }: {
        nixpkgs.overlays = [ fenix.overlays.default ];
        environment.systemPackages = with pkgs;
          let
            textEditors = [
              vim
              ((emacsPackagesFor (emacs.override {
                withNativeCompilation = false;
              })).emacsWithPackages (epkgs: [ epkgs.jinx ]))
            ];
            gitTools = [ git git-filter-repo ];
            aiTools = [ ollama ];
            libraries = [ iconv gnuplot graphviz readline ];
            commandLineTools = [ gnupg ];
            programmingLanguages = [
              openjdk
              poetry
              python3
              nodejs
              gcc
              go
              (pkgs.fenix.complete.withComponents [
                "cargo"
                "clippy"
                "rust-src"
                "rustc"
                "rustfmt"
              ])
              rust-analyzer-nightly
              taplo-lsp
              guile
              nixfmt-classic
            ];
            projectManagement = [ bear tokei ];
            shell = [ fish zoxide fzf ];
            applications = [
              qemu
              libqalculate
              telegram-desktop
              (callPackage ./pkgs/knockknock { })
            ];
          in textEditors ++ gitTools ++ aiTools ++ libraries ++ commandLineTools
          ++ programmingLanguages ++ projectManagement ++ shell ++ applications;

        nix.settings.experimental-features = [ "nix-command" "flakes" ];
      };
    in {
      # $ darwin-rebuild build --flake .#spectral
      darwinConfigurations.spectral = nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        specialArgs = inputs;
        modules = [
          configuration
          ./hosts/mac.nix
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
    };
}
