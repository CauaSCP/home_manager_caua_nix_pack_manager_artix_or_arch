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
    # 1. Define your variables here
    username = builtins.getEnv "USER";
    system = "x86_64-linux";
  in {
    homeConfigurations.default = home-manager.lib.homeManagerConfiguration {
      # 2. Use the system variable
      pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };

      extraSpecialArgs = { 
        inherit inputs username; 
        
        unstable-pkgs-unfree = import unstable-pkgs {
          inherit system;
          config.allowUnfree = true;
        };

        unstable-pkgs = import unstable-pkgs {
          inherit system;
          config.allowUnfree = false;
        };

        nixGlOutput = import nixgl {
          pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };
        };
      };

      modules = [ ./home.nix ];
    };
  };
}