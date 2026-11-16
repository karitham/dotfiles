# T3 Code, an agent client for the desktop: the `t3` server/CLI and the app it
# ships (`t3code-desktop`). home-manager has the module (`programs.t3code`,
# which owns the settings files and the headless server unit); this is the thin
# wrapper for what this repository decides for it: the daemon other devices
# pair with, the albedo ACP provider configured statically, and a server-only
# package for machines that have no app (../../pkgs/t3code-server).
#
# Albedo joins as a local ACP command (`albedo acp`, see ./albedo.nix). The
# provider instance is written into settings.json by activation, and the
# module's merge gives static keys precedence over the app's, so every client
# of this machine's server gets it without clicking Settings -> Providers.
#
# One server owns a T3 home at a time (`server-owner.sqlite`), so an app whose
# "local environment" is the same home cannot start; see
# `appLocalEnvironment`.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dev.t3code;
  daemon = cfg.daemon;

  # The app package also carries Electron and wraps `t3` with the provider CLIs
  # it drives; a machine that only serves other devices takes the server alone.
  package = if cfg.enable then cfg.package else daemon.package;

  acpInstances = lib.mapAttrs (_: agent: {
    driver = "acpRegistry";
    inherit (agent) displayName;
    enabled = true;
    config = {
      source = "local";
      commandPath = agent.executable;
      commandArgs = agent.arguments;
    };
  }) cfg.acpProviders;
in
{
  options.dev.t3code = {
    enable = lib.mkEnableOption "the T3 Code desktop app";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.callPackage ../../pkgs/t3code-nightly/package.nix { };
      defaultText = lib.literalExpression "pkgs.callPackage ../../pkgs/t3code-nightly/package.nix { }";
      description = "The desktop app and CLI to install for the client.";
    };

    userSettings = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = ''
        Extra settings.json, merged with ACP provider instances taking
        precedence. `programs.t3code.userSettings` owns the same file, so set it
        here rather than there.
      '';
    };

    acpProviders = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            displayName = lib.mkOption {
              type = lib.types.str;
              description = "Name in the provider list.";
            };
            executable = lib.mkOption {
              type = lib.types.str;
              description = "Absolute path to an ACP agent on this machine.";
            };
            arguments = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
              description = "Literal arguments, in launch order.";
            };
          };
        }
      );
      default = {
        albedo = {
          displayName = "Albedo";
          # Absolute, because the daemon's PATH is not a login shell's. The
          # package is the one home-manager installs, so it tracks albedo's
          # version on this host.
          executable = "${config.programs.albedo.package}/bin/albedo";
          arguments = [ "acp" ];
        };
      };
      defaultText = lib.literalExpression "{ albedo = { ... }; }";
      description = "ACP agents every client of this machine gets.";
    };

    daemon = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Run `t3 serve` as a systemd user service so agents keep running while
          no app is open, and so other devices can reach this machine.
        '';
      };

      expose = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Pass `--lan`, which makes the server accept connections from the local
          network and tailnet instead of only this machine. The firewall still
          decides what reaches it, and a pairing code is still required. Needs
          user lingering to answer before anyone logs in
          (`users.users.<name>.linger`).
        '';
      };

      port = lib.mkOption {
        type = lib.types.port;
        default = 3773;
        description = "Port the server listens on.";
      };

      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.callPackage ../../pkgs/t3code-nightly/package.nix { };
        defaultText = lib.literalExpression "pkgs.callPackage ../../pkgs/t3code-nightly/package.nix { }";
        description = ''
          What the unit runs when no app is installed. On a machine that only
          serves other devices, point this at `pkgs.t3code-server`
          (../../pkgs/t3code-server) to leave Electron out of the closure.
        '';
      };

      stopTimeout = lib.mkOption {
        type = lib.types.ints.positive;
        default = 300;
        description = ''
          Seconds a stop waits before SIGKILL. Agent turns run as children of
          the server, and any change to the unit restarts it, so a switch can
          cut a turn short; a short timeout makes that a kill instead of a wait.
        '';
      };
    };

    appLocalEnvironment = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Let the desktop app start its own server for its "local environment".
        One server owns a T3 home at a time, so on a host where the daemon is on
        the app's loses the ownership lock and shows a modal instead of its UI.
        Defaults to off in that case, and activation seeds that choice into the
        app's own settings file.
      '';
    };
  };

  config = lib.mkMerge [
    (lib.mkIf (cfg.enable || daemon.enable) {
      programs.t3code = {
        enable = true;
        inherit package;
        # The module merges these over the app's own file as static keys, which
        # is what makes the provider configuration stick.
        userSettings = lib.recursiveUpdate cfg.userSettings { providerInstances = acpInstances; };
      };
    })

    (lib.mkIf daemon.enable {
      # Off by default when the daemon owns the home; an explicit setting still
      # wins, because whoever asks for that conflict gets it.
      dev.t3code.appLocalEnvironment = lib.mkDefault false;

      programs.t3code.server = {
        enable = true;
        extraArgs = [
          "--port"
          (toString daemon.port)
        ]
        ++ lib.optional daemon.expose "--lan";
      };

      # The module leaves this at systemd's default, which kills in-flight
      # agent turns on the restart that any unit change causes.
      systemd.user.services.t3code.Service.TimeoutStopSec = daemon.stopTimeout;
    })

    # The daemon owns this home, so the app must not try to own it too. It keeps
    # that choice in its own settings file and preserves it across writes, so
    # seeding it once is enough; without this the app's first launch fails with
    # "This T3 home is unavailable" and no way in. Only the copy of the app
    # installed here reads this file, so it is written only where the app is.
    (lib.mkIf (cfg.enable && daemon.enable && !cfg.appLocalEnvironment) {
      home.activation.t3codeAppLocalEnvironment = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        settings=${lib.escapeShellArg "${config.home.homeDirectory}/.t3/userdata/desktop-settings.json"}
        jq=${pkgs.jq}/bin/jq

        if [ ! -s "$settings" ]; then
          install -d -m 700 "$(dirname "$settings")"
          printf '{"localEnvironmentEnabled":false}\n' > "$settings"
          chmod 600 "$settings"
        elif ! "$jq" -e . "$settings" > /dev/null 2>&1; then
          # Activation runs under `set -e`; a half-written or hand-edited file
          # must not abort the whole switch.
          warnEcho "t3code: $settings is not valid JSON, leaving it alone."
        elif [ "$("$jq" -r '.localEnvironmentEnabled // true' "$settings")" != "false" ]; then
          tmp="$settings.t3code-tmp"
          if "$jq" '.localEnvironmentEnabled = false' "$settings" > "$tmp"; then
            chmod --reference="$settings" "$tmp"
            mv "$tmp" "$settings"
          else
            rm -f "$tmp"
            warnEcho "t3code: could not turn off the app's local environment in $settings."
          fi
        fi
      '';
    })
  ];
}
