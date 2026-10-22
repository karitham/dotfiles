{
  config,
  lib,
  pkgs,
  self',
  ...
}:
let
  # The sops switch lives on opencode because it means "this host has a key in
  # .sops.yaml", which is true of gallant's secret too.
  useSops = config.dev.opencode.sops.enable;
  envFile = lib.attrByPath [ "gallant/env" "path" ] "/dev/null" config.sops.secrets;
  rulesDir = "${config.xdg.configHome}/gallant/rules";

  # Defaults gallant to Cloudflare, whose default model is clef, with the
  # decrypted credentials, and to the global rules when the working directory
  # has no .agents/gallant of its own. An environment value wins over these
  # defaults, so a shell can choose another provider, model, or rules directory;
  # gallant itself lets an explicit flag win over the environment.
  gallant = pkgs.symlinkJoin {
    name = "gallant";
    paths = [ self'.packages.gallant ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/gallant \
        --run 'if [ -f ${envFile} ]; then set -a; . ${envFile}; set +a; fi' \
        --set-default GALLANT_PROVIDER cloudflare \
        --run 'if [ ! -d .agents/gallant ]; then export GALLANT_RULES="''${GALLANT_RULES:-${rulesDir}}"; fi'
    '';
  };
in
{
  config = lib.mkIf config.dev.enable {
    sops.secrets."gallant/env" = lib.mkIf useSops {
      sopsFile = ../../../secrets/gallant.env;
      format = "dotenv";
    };

    xdg.configFile."gallant/rules".source = ./gallant/rules;

    home.packages = [ gallant ];
  };
}
