{
  description = "Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixcord.url = "github:FlameFlag/nixcord";
  };

  outputs = { nixpkgs, home-manager, nixcord, ... }@inputs:
    let
      parts = builtins.filter (x: x != "") (
        builtins.split "/" (builtins.toString ./.)
      );
      usernameFromHome = builtins.elemAt parts 1;
    in {
      homeConfigurations."caua" =
        home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          extraSpecialArgs = { inherit inputs; };
          modules = [ ./home.nix ];
        };
    };
}