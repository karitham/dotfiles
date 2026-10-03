{
  config,
  inputs,
  lib,
  pkgs,
  self',
  inputs',
  ...
}:
let
  cfg = config.dev.opencode;

  # Path to the sops-decrypted env file, or /dev/null if not configured.
  # The wrapper uses `[ -f ... ]` to skip if missing, so opencode always starts
  # even on machines where sops can't decrypt.
  opencodeEnvFile = lib.attrByPath [ "opencode/env" "path" ] "/dev/null" config.sops.secrets;

  sliceName = "opencode.slice";

  # systemd-run has to hand off the real binary on the same exec line; as a
  # --scope it runs that command, it does not wrap a later one. The trailing
  # space is load-bearing.
  systemdRunPrefix = lib.optionalString cfg.resourceLimits "${lib.getExe' pkgs.systemd "systemd-run"} --user --scope --quiet --same-dir --slice=${sliceName} -- ";

  # Hand-written rather than makeWrapper: the systemd-run hand-off has to be the
  # exec itself, and wrapProgram --run lines land before the final exec.
  opencodePkg' =
    pkg: name:
    pkgs.writeShellApplication {
      name = name;
      text = ''
        # shellcheck disable=SC1091
        if [ -f "${opencodeEnvFile}" ]; then set -a; . "${opencodeEnvFile}"; set +a; fi

        export OPENCODE_DISABLE_LSP_DOWNLOAD=true
        export OPENCODE_DISABLE_AUTOUPDATE=true
        export OPENCODE_EXPERIMENTAL_MARKDOWN=true
        export OPENCODE_ENABLE_EXA=true
        export SHELL=${lib.getExe pkgs.bash}

        exec ${systemdRunPrefix}${pkg}/bin/${name} "$@"
      '';
    };
in
{
  imports = [ inputs.sops-nix.homeManagerModules.sops ];

  options.dev.opencode = {
    enable = lib.mkEnableOption "OpenCode AI-assisted development environment";
    enableMcp = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "MCP server integrations for enhanced language support";
    };
    theme = lib.mkOption {
      type = lib.types.str;
      default = "catppuccin-macchiato";
      description = "OpenCode theme";
    };
    modelFast = lib.mkOption {
      type = lib.types.str;
      default = "opencode-go/deepseek-v4.1-flash";
    };
    modelSmart = lib.mkOption {
      type = lib.types.str;
      default = "opencode-go/deepseek-v4.1-flash";
    };
    modelAdversarial = lib.mkOption {
      type = lib.types.str;
      # used to be glm but it's way too slow. I'd prefer to diversify but it is what it is
      default = "opencode-go/deepseek-v4.1-flash";
    };
    plugins = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = ''
        OpenCode V2 `plugins` entries: npm package names or paths to a local
        plugin directory. V2-only; the V1 `opencode` binary ignores this key.
        Set to `[ ]` on hosts without the referenced plugin.
      '';
    };
    mcpBrowser = lib.mkOption {
      type = lib.types.nullOr lib.types.package;
      default = null;
      description = ''
        Browser the chrome-devtools MCP drives, passed as --executablePath.
        Null leaves the flag off and lets the server look for a Chrome itself.
        Desktop hosts set this to helium (modules/desktop/apps/browser.nix);
        override it per host to use a different browser.
      '';
    };
    resourceLimits = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Run opencode in opencode.slice, whose memory, swap and process-count
        limits contain anything the agent runs, including shell commands and MCP
        servers. Set false on hosts without a systemd user manager, where the
        slice cannot exist.
      '';
    };
    sops.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Use sops-backed secrets for opencode MCP servers (Linear, Sentry, GitHub, Kagi).
        Disable on machines that don't have a registered SSH key in .sops.yaml —
        the wrapper will still let opencode start, just without the secret-needing MCPs.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets."opencode/env" = lib.mkIf cfg.sops.enable {
      sopsFile = ../../secrets/opencode.env;
      format = "dotenv";
    };

    # `programs.opencode.package` above already installs this wrapper, so it is
    # not repeated in home.packages.

    # OCR config — single source of truth, reuses the opencode-go auth
    # already present in ~/.local/share/opencode/auth.json. The api_key is
    # resolved via api_key_cmd so no secret lands in the nix store.
    # Endpoint + model verified against https://opencode.ai/docs/go/#endpoints
    home.file.".opencodereview/config.json".text = builtins.toJSON {
      provider = "opencode-go";
      custom_providers = {
        "opencode-go" = {
          url = "https://opencode.ai/zen/go/v1";
          protocol = "openai";
          model = cfg.modelSmart;
          api_key_cmd = "${lib.getExe pkgs.jq} -r '.[\"opencode-go\"].key' ${config.home.homeDirectory}/.local/share/opencode/auth.json";
        };
      };
    };

    # opencode runs in a scope inside this slice, so everything it spawns —
    # shell commands, MCP servers — inherits these limits. cgroup v2 applies a
    # parent's ceiling to the whole subtree, which is what contains a runaway
    # command: it is throttled and killed inside its own cgroup instead of the
    # kernel OOM killer picking a victim elsewhere on the machine.
    #
    # Sized for a 16G/16-core desktop. MemoryMax is the load-bearing one;
    # MemoryHigh makes builds slow down rather than die. CPU/IO weights yield to
    # interactive work under contention without capping throughput.
    #
    # Keys are systemd's own: on a slice unit the resource-control directives live
    # in [Slice]. Anything that isn't a declared home-manager option lands in the
    # unit verbatim, so a made-up `sliceConfig` key would render as a literal
    # `[sliceConfig]` section that systemd ignores.
    systemd.user.slices.opencode = lib.mkIf cfg.resourceLimits {
      Unit.Description = "OpenCode Slice";
      Slice = {
        MemoryMax = "8G";
        MemoryHigh = "6G";
        MemorySwapMax = "2G";
        # Bound fork bombs; nix builds need nowhere near this.
        TasksMax = "8192";
        CPUWeight = "50";
        IOWeight = "50";
      };
    };

    programs.opencode = {
      enable = true;
      package = opencodePkg' inputs'.llm-agents.packages.opencode2 "opencode2";
      enableMcpIntegration = cfg.enableMcp;
      commands = (
        lib.mapAttrs' (name: _: lib.nameValuePair (lib.removeSuffix ".md" name) (./commands + "/${name}")) (
          lib.filterAttrs (n: v: v == "regular" && lib.hasSuffix ".md" n) (builtins.readDir ./commands)
        )
      );
      agents = ./agents;
      skills = toString (
        pkgs.symlinkJoin {
          name = "opencode-skills";
          paths = [
            ./skills
            ../dev/tools/tuicr
            # self'.packages.strands-agents-sops-skills
          ];
        }
      );
      settings = {
        lsp = false;
        inherit (cfg) theme;
        default_agent = "pair";
        agent = {
          pair.model = cfg.modelSmart;
          reviewer.model = cfg.modelAdversarial;
          suckless.model = cfg.modelAdversarial;
          taste.model = cfg.modelFast;
          explore.model = cfg.modelFast;
        };
        formatter = {
          nixfmt = {
            command = [
              "nixfmt"
              "-s"
              "-w"
              "120"
              "$FILE"
            ];
            extensions = [ ".nix" ];
          };
          gofmt = {
            disabled = true;
          };
          goimports = {
            command = [
              "goimports"
              "-w"
              "$FILE"
            ];
            extensions = [ ".go" ];
          };
          sql-formatter = {
            command = [
              "sql-formatter"
              "-c"
              (builtins.toJSON {
                keywordCase = "upper";
                functionCase = "upper";
                dataTypeCase = "upper";
                identifierCase = "lower";
                language = "postgresql";
                expressionWidth = 80;
                tabWidth = 2;
              })
              "$FILE"
            ];
            extensions = [ ".sql" ];
          };
          nufmt = {
            command = [
              "nufmt"
              "--stdin"
            ];
            extensions = [ ".nu" ];
          };
        };
        permission = {
          todoread = "deny";
          todowrite = "deny";
          external_directory = {
            "~/*" = "allow"; # yolo.
            "/tmp/*" = "allow";
          };
        };
        mcp = lib.mkIf cfg.enableMcp {
          # outline doesn't need secrets, always available
          outline = {
            type = "remote";
            url = "https://outline.dolly-ruffe.ts.net/mcp";
            enabled = true;
          };

          # These need secrets from sops, only configured when sops is enabled
          github = lib.mkIf cfg.sops.enable {
            type = "remote";
            url = "https://api.githubcopilot.com/mcp/";
            enabled = true;
            headers = {
              Authorization = "Bearer {env:GITHUB_TOKEN}";
            };
          };

          kagi = lib.mkIf cfg.sops.enable {
            type = "remote";
            url = "https://mcp.kagi.com/mcp";
            oauth = false;
            enabled = false;
            headers = {
              Authorization = "Bearer {env:KAGI_API_KEY}";
            };
          };

          # Off by default: it launches a real browser.
          chrome-devtools = {
            type = "local";
            enabled = false;
            command = [
              (lib.getExe self'.packages.chrome-devtools-mcp)
            ]
            ++ lib.optionals (cfg.mcpBrowser != null) [
              "--executablePath"
              (lib.getExe cfg.mcpBrowser)
            ];
          };
        };
      }
      // lib.optionalAttrs (cfg.plugins != [ ]) { inherit (cfg) plugins; };
    };
  };
}
