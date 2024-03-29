{
  description = "A very basic example using shoji-nix";
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    shoji-nix.url = "github:AdoPi/shoji-nix";
  };

  outputs = inputs @ { self, nixpkgs, home-manager, shoji-nix, ... }:
    let system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };
    lib = nixpkgs.lib;
    in {
      nixosConfigurations = {
        laptop = lib.nixosSystem {
	  inherit system;
	  modules = [
            shoji-nix.nixosModules.shoji
            ./secrets
          ];
        };
      };
    };
}
