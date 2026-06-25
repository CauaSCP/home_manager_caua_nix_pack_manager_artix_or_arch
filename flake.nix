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
    # This runs in your shell, so it correctly gets "caua"
    username = builtins.getEnv "USER";
  in {
    homeConfigurations.default = home-manager.lib.homeManagerConfiguration {
      pkgs = import nixpkgs { system = "x86_64-linux"; config.allowUnfree = true; };

      # PASS the username here!
      extraSpecialArgs = { 
        inherit inputs username; 
        
        unstable-pkgs-unfree = import unstable-pkgs {
          system = "x86_64-linux";
          config.allowUnfree = true;
        };
        # ... (rest of your extraSpecialArgs)

        unstable-pkgs = import unstable-pkgs {
          inherit system;
          config.allowUnfree = false;
        };

        nixGlOutput = import nixgl {
          inherit pkgs;
        };
      };

      modules = [ ./home.nix ];
    };
  };
}