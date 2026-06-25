{ config, lib, pkgs, ... }:

let
  nixgl = import <nixgl> {};
  nixGLWrapper = nixgl.auto.nixGLDefault;

  # --- CONFIGURAÇÃO DO .unfrees.json COM FALLBACK ---
  targetUid = 1000;
  
  usersAttrs = config.users.users or config.osConfig.users.users or {};
  usernames = builtins.attrNames usersAttrs;
  
  otherUsername = lib.findFirst 
    (name: (usersAttrs.${name}.uid or null) == targetUid) 
    "unknown-user"
    usernames;

  otherHomeDir = "/home/${otherUsername}";
  relativeFilePath = ".unfrees.json";

  currentHomeDir = config.home.homeDirectory or (builtins.getEnv "HOME");
  currentUserFile = "${currentHomeDir}/${relativeFilePath}";
  fallbackUserFile = "${otherHomeDir}/${relativeFilePath}";

  finalFilePath = if builtins.pathExists currentUserFile 
                  then currentUserFile 
                  else fallbackUserFile;

  allowedUnfreeList = if builtins.pathExists finalFilePath
                      then (builtins.fromJSON (builtins.readFile finalFilePath)).allowed or []
                      else [];

  # --- ESPELHOS DE CONSULTA SEGUROS ---
  stableLookup = import <nixpkgs> { config = { allowUnfree = true; }; };
  unstableLookup = if (builtins.tryEval <unstable>).success 
                   then import <unstable> { config = { allowUnfree = true; }; }
                   else stableLookup;

  checkPackageInRepo = repo: pkg: allowedAttr:
    builtins.hasAttr allowedAttr repo && (
      let 
        repoPkg = repo.${allowedAttr};
      in
        pkg.version == repoPkg.version && (
          pkg.pname == allowedAttr 
          || (repoPkg ? pname && pkg.pname == repoPkg.pname)
        )
    );

  # --- WRAPPER DO NIXGL ---
  wrapWithNixGL = pkg: pkgs.runCommand "${pkg.name}-nixgl-wrapper" {} ''
    mkdir -p $out
    for dir in ${pkg}/*; do
      base=$(basename "$dir")
      if [ "$base" != "bin" ] && [ "$base" != "share" ]; then
        ln -s "$dir" "$out/$base"
      fi
    done

    if [ -d "${pkg}/share" ]; then
      mkdir -p $out/share
      for sdir in ${pkg}/share/*; do
        sbase=$(basename "$sdir")
        if [ "$sbase" != "applications" ]; then
          ln -s "$sdir" "$out/share/$sbase"
        fi
      done
    fi

    mkdir -p $out/bin
    for bin in ${pkg}/bin/*; do
      bin_name=$(basename $bin)
      wrapped_bin=$out/bin/$bin_name

      if [ "$bin_name" = "kitty" ]; then
        echo -e "#!/usr/bin/env bash\nexport HOME=${otherHomeDir}\nexec ${lib.getExe' nixGLWrapper "nixGL"} \"$bin\" --config ${otherHomeDir}/.config/kitty/kitty.conf \"\$@\"" > $wrapped_bin
      else
        echo -e "#!/usr/bin/env bash\nexec ${lib.getExe' nixGLWrapper "nixGL"} \"$bin\" \"\$@\"" > $wrapped_bin
      fi

      chmod +x $wrapped_bin
    done

    if [ -d "${pkg}/share/applications" ]; then
      mkdir -p $out/share/applications
      for desktop in ${pkg}/share/applications/*.desktop; do
        wrapped_desktop=$out/share/applications/$(basename $desktop)
        exec_name=$(grep -E '^Exec=' "$desktop" | head -n1 | sed 's|Exec=||; s| .*||; s|.*/||')
        sed "s|Exec=[^ ]*|Exec=$out/bin/$exec_name|g" "$desktop" > "$wrapped_desktop"
      done
    fi
  '';

  # --- LISTAS ORIGINAIS DE NOMES ---
  guiNames = import ./gui-packages.nix;
  cliNames = import ./cli-packages.nix;

  unstablePkgs = if (builtins.tryEval <unstable>).success 
                 then import <unstable> { config = { allowUnfree = true; }; }
                 else pkgs;

  # --- PROCESSADOR DE PACOTES COM FILTRO PURAMENTE EM BUILD-TIME ---
  processPackage = isGui: name:
    let
      rawPkg = if builtins.hasAttr name unstablePkgs then unstablePkgs.${name}
               else if builtins.hasAttr name pkgs then pkgs.${name}
               else abort "Erro: O pacote '${name}' não foi encontrado.";

      isUnfree = rawPkg ? meta.license && (
        let lic = rawPkg.meta.license;
        in if builtins.isList lic 
           then builtins.any (l: l ? free && l.free == false) lic 
           else (lic ? free && lic.free == false)
      );

      isAllowed = builtins.any (allowedAttr:
        checkPackageInRepo stableLookup rawPkg allowedAttr
        || checkPackageInRepo unstableLookup rawPkg allowedAttr
      ) allowedUnfreeList;
    in
      if isUnfree && !isAllowed then
        pkgs.runCommand "erro-unfree-${name}" {} ''
          echo ""
          echo "❌ [Erro] O pacote proprietário '${name}' requer uma licença unfree, mas não foi autorizado no seu arquivo '${relativeFilePath}'."
          echo "👉 Adicione \"${name}\" na lista 'allowed' do seu JSON para permitir."
          echo ""
          exit 1
        ''
      else
        if isGui then wrapWithNixGL rawPkg else rawPkg;

  processedCliPackages = map (processPackage false) cliNames;
  processedGuiPackages = map (processPackage true) guiNames;

in {
  # Liberamos unfree globalmente na avaliação para desativar os erros nativos do Nixpkgs.
  nixpkgs.config.allowUnfree = true;

  home.packages = processedCliPackages ++ processedGuiPackages;
}