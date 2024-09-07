{
  description = "Home Manager configuration with shoji module";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    shoji-nix.url = "github:AdoPi/shoji-nix";
  };

  outputs = { self, nixpkgs, home-manager, shoji-nix }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      homeManager = home-manager.lib.homeManagerConfiguration;
    in {
      myHome = {
        myuser = homeManager {
          inherit pkgs;
          modules = [
            shoji-nix
            ./home.nix
          ];
        };
      };
    };
}
