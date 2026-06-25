{ config, pkgs, inputs, unstable-pkgs-unfree, username, ... }: 

{
  imports = [
    ./.nixGL/home-manager/other_home.nix
  ];

  # Now these are dynamic and never hardcoded
  home.username = username;
  home.homeDirectory = "/home/${username}";
  home.stateVersion = "25.11";

  home.packages = [
    (config.lib.nixGL.wrap unstable-pkgs-unfree.discord)
  ];

  programs.home-manager.enable = true;
}