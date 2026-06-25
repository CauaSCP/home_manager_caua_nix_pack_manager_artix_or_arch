{ config, lib, pkgs, inputs, ... }:

let
  unstable = import <unstable-pkgs> { 
    config = config.nixpkgs.config; 
  };
in
{
  # Outros perfis e imports
  imports = [
    ./.nixGL/home-manager/other_home.nix
    inputs.nixcord.homeModules.nixcord
  ];

  home.username = "caua";
  home.homeDirectory = "/home/caua";
  home.stateVersion = "25.11";

  # SOLUÇÃO: Adiciona um overlay para consertar o atalho quebrado antes da instalação
  
  # O OVERLAY CORRIGIDO COM VENCORD:
  nixpkgs.overlays = [
    (final: prev: {
      discord-fixed = ((unstable.pkgs.discord.override { 
        # 1. Ativa o Vencord na receita do pacote instável
        withVencord = true; 
      }).overrideAttrs (oldAttrs: {
        # 2. Mantém a nossa correção que limpa o atalho .desktop corrompido
        postInstall = (oldAttrs.postInstall or "") + ''
          rm -rf $out/share/applications
          mkdir -p $out/share/applications
          echo -e "[Desktop Entry]\nName=Discord\nExec=Discord\nType=Application\nIcon=discord" > $out/share/applications/discord.desktop
        '';
      }));
    })
  ];

  # Limpa o comando builder temporário anterior
  home.enableDebugInfo = false;

  home.packages = [
    # Chama o nosso pacote corrigido pelo overlay e passa para o nixGL
    (config.lib.nixGL.wrap unstable.pkgs.discord)
  ];

  programs.nixcord = {
    enable = true;
    vesktop.enable = true; # Using Vesktop client for better Vencord stability
    
    config = {
      useQuickCss = true;
      plugins = {
        volumeBooster.enable = true;
        friendCorner.enable = true;
        shikiCodeblocks.enable = true;
      };
    };
  };
  /*

        fakeNitro.enable = true;

  */

  # ... Mantenha todo o restante do arquivo (programs.home-manager.enable, etc) IGUAL ...
  programs.home-manager.enable = true;
}
