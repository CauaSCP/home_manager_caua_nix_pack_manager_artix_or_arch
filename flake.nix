{
  description = "Home Manager configuration";

  inputs = {
    nixgl.url = "github:nix-community/nixGL";
    unstable-pkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixgl, nixpkgs, unstable-pkgs, home-manager, ... }@inputs: 
    let
      username = builtins.getEnv "USER";
    in {
      homeConfigurations = if username == "" then 
        throw "Could not determine username from environment variable $USER. Please set it."
        else {
          "${username}" = home-manager.lib.homeManagerConfiguration {
            pkgs = import nixpkgs {
              system = "x86_64-linux";
              config.allowUnfree = true;
            };

            extraSpecialArgs = {
              inherit inputs;

              unstable-pkgs-unfree = import unstable-pkgs {
                system = "x86_64-linux";
                config.allowUnfree = true;
              };

              unstable-pkgs = import unstable-pkgs {
                system = "x86_64-linux";
                config.allowUnfree = false;
              };

              nixGlOutput = import nixgl {
                pkgs = import nixpkgs {
                  system = "x86_64-linux";
                  config.allowUnfree = true;
                };
              };
            };

            modules = [
              ./home.nix
            ];
          };
        };
    };
}