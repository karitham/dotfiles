{ pkgs, ... }:

let
  version = "unstable-2026-07-01";
  src = pkgs.fetchFromGitHub {
    owner = "Vencord";
    repo = "Vesktop";
    rev = "29c11f3191d8bd8d1e3ba6fecee4c3e880181dd6";
    hash = "sha256-XqdLYGqIyohNheK9qXpap2hZ8ejhB66WdrYB6FReVLk=";
  };
in
(pkgs.vesktop.override {
  electron_40 = pkgs.electron_42;
  pnpm_10_29_2 = pkgs.pnpm_11;
}).overrideAttrs
  (old: {
    inherit version src;

    pnpmDeps = pkgs.fetchPnpmDeps {
      pname = old.pname;
      inherit version src;
      pnpm = pkgs.pnpm_11;
      fetcherVersion = 3;
      hash = "sha256-Ghs4cz5Yn7bWBvp2SstiWvf+ldWRi1XXVSa08/FqL6g=";
      prePnpmInstall = ''
        export pnpm_config_minimum_release_age=0
      '';
    };

    # Skip electron version check — package.json declares ^43 but we use 42
    preBuild = ''
      cp -r ${pkgs.electron_42.dist} electron-dist
      chmod -R u+w electron-dist
    '';
  })
