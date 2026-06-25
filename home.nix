{ config, pkgs, inputs, unstable-pkgs-unfree, unstable-pkgs, ... }: 

let
  unstable-pkgs-unfree-let = import <unstable-pkgs-unfree>;
in
{
  imports = [
    ./.nixGL/home-manager/other_home.nix
  ];

  home.username = "caua";
  home.homeDirectory = "/home/caua";
  home.stateVersion = "25.11";

  home.packages = [
    (config.lib.nixGL.wrap unstable-pkgs-unfree.discord)
  ];

  programs.home-manager.enable = true;
}