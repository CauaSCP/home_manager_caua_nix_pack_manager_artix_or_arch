{ config, pkgs, inputs, unstable-pkgs, ... }: 

let
  unstable-pkgs-let-var = import <unstable-pkgs>;
in
{
  imports = [
    ./.nixGL/home-manager/other_home.nix
  ];

  home.username = "caua";
  home.homeDirectory = "/home/caua";
  home.stateVersion = "25.11";

  home.packages = [
    (config.lib.nixGL.wrap unstable-pkgs.discord)
  ];

  programs.home-manager.enable = true;
}