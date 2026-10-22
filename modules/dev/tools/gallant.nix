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

  # Defaults gallant to Cloudflare's clef with the decrypted credentials, and to
  # the global rules when the working directory has no .agents/gallant of its
  # own. An explicit --provider turns off the provider default, so another
  # provider never inherits a clef --model it does not serve. An explicit
  # --rules needs no check: gallant keeps the last occurrence of a flag.
  gallant = pkgs.writeShellScriptBin "gallant" ''
    if [ -f ${envFile} ]; then
      set -a
      . ${envFile}
      set +a
    fi

    for arg in "$@"; do
      case "$arg" in
        -provider | -provider=* | --provider | --provider=*) provider_given=1 ;;
      esac
    done

    defaults=()
    [ -n "$provider_given" ] || defaults+=(--provider cloudflare --model clef)
    [ -d .agents/gallant ] || defaults+=(--rules ${rulesDir})

    exec ${lib.getExe self'.packages.gallant} "''${defaults[@]}" "$@"
  '';
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
