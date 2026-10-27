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
  # Shell entrypoint for OpenCode 2's shell tool. Wraps the real shell in a
  # systemd user scope so each tool command gets its own cgroup: a runaway is
  # OOM-killed in isolation, and under CPU contention it yields to the rest of
  # the system. Falls back to an unconfined shell when no user manager is
  # reachable, so it cannot break machines without systemd.
  #
  # OPENCODE_SCOPED_SHELL pins the real shell to the same bash the opencode
  # wrapper sets as $SHELL, so the two stay consistent.
  opencodeScopedShell = pkgs.writeShellApplication {
    name = "opencode-scoped-shell";
    runtimeInputs = [
      pkgs.bash
      pkgs.systemd
    ];
    text = ''
      export OPENCODE_SCOPED_SHELL=${lib.getExe pkgs.bash}
    ''
    + builtins.readFile ./shell-scoped.sh;
  };

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
    attachBrowser = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        DevToolsActivePort file of a browser that is already running, as a path
        this machine can read. When set, the chrome-devtools MCP attaches to
        that browser over CDP instead of launching one, so the agent sees the
        tabs and logged-in sessions of the user's own profile.

        The file holds two lines: the CDP port, then the
        /devtools/browser/<uuid> socket path. Chromium serves no
        /json/version on that implicit endpoint, so the server needs
        --wsEndpoint rather than --browserUrl, and it must read the file at
        connect time because the uuid changes on every browser start.
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

    # OCR config: single source of truth, reuses the opencode-go auth
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

    # The V2 binary ships the built-in tools as native, model-facing tools
    # (`codemode: false`); everything else is deferred behind Code Mode. This
    # plugin flips the built-ins into Code Mode, so the model-facing list
    # collapses to `execute`, `skill` and `subagent`, and every other tool is
    # callable from inside a Code Mode program. It is discovered from the global
    # `plugins/` directory; disable it per host with
    # `settings.plugins = [ "-all-tools-codemode" ]`.
    xdg.configFile."opencode/plugins/all-tools-codemode.ts".source = ./plugins/all-tools-codemode.ts;

    # opencode runs in a scope inside this slice, so everything it spawns (shell
    # commands, MCP servers) inherits these limits. cgroup v2 applies a
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
            # symlinkJoin merges directory contents, so the skill must sit in
            # its own subdirectory; a SKILL.md at the root shadows every other skill.
            (pkgs.linkFarm "tuicr-skill" [
              {
                name = "tuicr/SKILL.md";
                path = ../dev/tools/tuicr/SKILL.md;
              }
            ])
            # self'.packages.strands-agents-sops-skills
          ];
        }
      );
      settings = {
        lsp = false;
        inherit (cfg) theme;
        default_agent = "pair";
        # Run tool commands in a systemd user scope (see opencodeScopedShell).
        shell = lib.getExe opencodeScopedShell;
        agent = {
          pair.model = cfg.modelSmart;
          reviewer.model = cfg.modelAdversarial;
          pair-staging.model = cfg.modelSmart;
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

          # Off unless a host points it at a running browser: the fallback
          # branch launches one, which is a blank profile and no sessions.
          chrome-devtools = {
            type = "local";
            enabled = cfg.attachBrowser != null;
            command =
              if cfg.attachBrowser != null then
                [
                  "bash"
                  "-lc"
                  (
                    "f=${lib.escapeShellArg cfg.attachBrowser}; "
                    + "exec ${lib.getExe self'.packages.chrome-devtools-mcp} "
                    + "--wsEndpoint \"ws://127.0.0.1:$(sed -n 1p \"$f\")$(sed -n 2p \"$f\")\""
                  )
                ]
              else
                [ (lib.getExe self'.packages.chrome-devtools-mcp) ]
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
