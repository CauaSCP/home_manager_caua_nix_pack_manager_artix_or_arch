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

  outputs = { nixpkgs, home-manager, nixcord, ... }@inputs: {
    homeConfigurations."YOUR_USERNAME" = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.x86_64-linux; # Change to aarch64-linux if you are on ARM
      extraSpecialArgs = { inherit inputs; };
      modules = [ ./home.nix ];
    };
  };
}