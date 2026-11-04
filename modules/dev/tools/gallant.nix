{
  config,
  lib,
  pkgs,
  self',
  ...
}:
let
  # The sops switch lives on the agents because it means "this host has a key
  # in .sops.yaml", which is true of gallant's secret too.
  useSops = config.dev.agents.sops.enable;
  envFile = lib.attrByPath [ "gallant/env" "path" ] "/dev/null" config.sops.secrets;
  rulesDir = "${config.xdg.configHome}/gallant/rules";

  local = config.dev.gallant.local;
  localURL = "http://127.0.0.1:${toString local.port}";

  # gallant-llama starts the local server on demand and leaves it warm. The
  # wrapper calls it before a run, so the first run pays the model load.
  llamaServer = pkgs.writers.writeNuBin "gallant-llama" {
    makeWrapperArgs = [
      "--prefix PATH : ${
        lib.makeBinPath [
          pkgs.coreutils
          pkgs.procps
          pkgs.util-linux
          local.package
        ]
      }"
    ];
  } (builtins.readFile ./gallant/llama-server.nu);

  # Defaults gallant to the local Liquid d1 model when enabled, and to
  # Cloudflare otherwise. An environment value wins over these defaults, so a
  # shell can choose another provider, model, or rules directory; gallant
  # itself lets an explicit flag win over the environment.
  gallant = pkgs.symlinkJoin {
    name = "gallant";
    paths = [ self'.packages.gallant ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/gallant \
        --run 'if [ -f ${envFile} ]; then set -a; . ${envFile}; set +a; fi' \
        --set-default GALLANT_PROVIDER ${if local.enable then "liquid" else "cloudflare"} \
        ${lib.optionalString local.enable ''
          --set-default GALLANT_MODEL d1-2B \
          --set-default LIQUID_BASE_URL ${localURL} \
          --set-default GALLANT_LLAMA_MODEL ${lib.escapeShellArg local.model} \
          --set-default GALLANT_LLAMA_CONTEXT ${toString local.contextSize} \
          --set-default GALLANT_LLAMA_THREADS ${toString local.threads} \
          --set-default GALLANT_LLAMA_GPU_LAYERS ${toString local.gpuLayers} \
          --run 'set -- --jobs ${toString local.jobs} "$@"' \
          --run '${llamaServer}/bin/gallant-llama ensure -- "$@" || exit $?' \
        ''} \
        --run 'if [ ! -d .agents/gallant ]; then export GALLANT_RULES="''${GALLANT_RULES:-${rulesDir}}"; fi'
    '';
  };
in
{
  options.dev.gallant.local = {
    enable = lib.mkEnableOption "a local llama-server for Liquid d1 decision models";

    port = lib.mkOption {
      type = lib.types.port;
      default = 18080;
      description = "Port the local llama-server listens on.";
    };

    model = lib.mkOption {
      type = lib.types.str;
      default = "LiquidAI/d1-2B-GGUF:Q8_0";
      description = ''
        Model passed to llama-server. A Hugging Face repository and quantization
        is fetched on first use; a path ending in .gguf is loaded directly.
      '';
    };

    contextSize = lib.mkOption {
      type = lib.types.ints.positive;
      default = 16384;
      description = "Context, batch, and micro-batch size for the local server.";
    };

    threads = lib.mkOption {
      type = lib.types.ints.positive;
      default = 8;
      description = "CPU threads the local server uses.";
    };

    jobs = lib.mkOption {
      type = lib.types.ints.positive;
      default = 1;
      description = ''
        Files gallant evaluates at once against the local server. CPU inference
        is fastest with one; raise this for a GPU build.
      '';
    };

    gpuLayers = lib.mkOption {
      type = lib.types.ints.unsigned;
      default = 0;
      description = "Layers offloaded to the GPU; 0 keeps the server on CPU.";
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.callPackage ../../../pkgs/llama-cpp-d1/package.nix { };
      description = "llama.cpp build that provides llama-server with systemone support.";
    };
  };

  config = lib.mkIf config.dev.enable {
    sops.secrets."gallant/env" = lib.mkIf useSops {
      sopsFile = ../../../secrets/gallant.env;
      format = "dotenv";
    };

    xdg.configFile."gallant/rules".source = ./gallant/rules;

    home.packages = [
      gallant
    ]
    ++ lib.optionals local.enable [
      llamaServer
      local.package
    ];
  };
}
