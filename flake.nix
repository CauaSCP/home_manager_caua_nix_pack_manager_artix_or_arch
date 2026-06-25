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
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in {
      # By using 'default', we avoid hardcoding the username in the attribute path.
      homeConfigurations.default = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;

        extraSpecialArgs = {
          inherit inputs;

          unstable-pkgs-unfree = import unstable-pkgs {
            inherit system;
            config.allowUnfree = true;
          };

          unstable-pkgs = import unstable-pkgs {
            inherit system;
            config.allowUnfree = false;
          };

          nixGlOutput = import nixgl {
            inherit pkgs;
          };
        };

        modules = [
          ./home.nix
        ];
      };
    };
}