{ config, lib, pkgs, ... }:

{
    unstable-pkgs = import _unstablePackages {
      system = "x86_64-linux";
    };
}