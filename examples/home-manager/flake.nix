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
      username = "myuser";
      pkgs = import nixpkgs { inherit system; };
      homeManager = home-manager.lib.homeManagerConfiguration;
    in {
	example = lib.nixosSystem {
	  inherit system;
	  modules = [
	    home-manager.nixosModules.home-manager
            {
	      home-manager.sharedModules = [
	        shoji-nix.homeManagerModules.shoji
	      ];
	      home-manager.useGlobalPkgs = true;
	      home-manager.useUserPackages = true;
	      home-manager.users.${username} = import ./home {inherit username;};
	    }

	  ];
	};
    };
}
