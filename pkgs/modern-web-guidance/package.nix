# GoogleChrome's Modern Web Guidance, as the one artifact that matters: the
# built skill. Its SKILL.md and the CLI its commands run ship together in the
# npm tarball -- the git repo carries only the skill and its guides, the search
# index (gen/) is generated -- so the tarball is fetched and laid out as the
# skill directory, with that CLI pointing at the node it was built with. Nothing
# lands on PATH: like the guided-review skill, it is invoked through its own
# path under ~/.agents/skills.
{
  lib,
  stdenvNoCC,
  fetchurl,
  nodejs,
}:

let
  pname = "modern-web-guidance";
  version = "1.0.0";

  # How the skill reaches the CLI once installed, the same shape as
  # guided-review's `python3 ~/.agents/skills/guided-review/render.py`.
  cli = "~/.agents/skills/${pname}/modern-web.mjs";

  # Upstream's SKILL.md fetches the CLI with npx on every run, which is also
  # how it is installed; here the file beside the skill is the command.
  npxPrefix = "npx -y modern-web-guidance@latest";

  # Upstream's notes on running through npx, and on asking for network access
  # for it: none of it applies to a CLI that is already here.
  npxSection = ''
    ## Using npx / pnpx

    - **Runner & Permissions**: Prefer `pnpx` over `npx` if `pnpm` is available (`pnpx` does not use `-y`); on Windows, use `npx.cmd`. When requesting tool permissions, allowlist `npx -y modern-web-guidance@latest *` (or `pnpx modern-web-guidance@latest *`) specifically, never bare `npx *` or `pnpx *`.
    - **Sandboxes & Network**: Fetching `modern-web-guidance` requires outbound network access. In sandboxed or approval-gated environments (e.g., Codex, Claude Code), **proactively request approval/allowlisting with network access BEFORE the first execution** to avoid timeouts, and set `NPM_CONFIG_CACHE=/tmp/npm-cache` if `~/.npm` is read-only.
    - **Offline**: If the command hangs due to being offline, retry with `npx --offline …`.

  '';

  # The one line of prose that still reaches for npx: installed, the CLI is a
  # file, run as spelled out above.
  proseFrom = "Run `modern-web-guidance` directly with `npx` using a **2–5 word action-oriented query**";
  proseTo = "Run it directly, using a **2–5 word action-oriented query**";

  newSection = ''
    ## Running the CLI

    `~/.agents/skills/modern-web-guidance/modern-web.mjs` is this skill's own copy:
    it reads `gen/` and `guides/` from the same directory, so every command above
    runs offline, with no `npx`, no npm cache and no allowlist. Its shebang is the
    node it was built with, so it needs nothing on `PATH`. The `--skill-version`
    argument pins which release of the guides answered; here the skill and the CLI
    ship together, so it always matches. Do not run `install`, `update` or
    `uninstall`: nix owns this directory, and those shell out to npx for a second
    copy.
  '';

  # Every replacement below fails the build when it no longer matches, so a
  # bump that reworded the skill cannot ship commands that do not run.
  rewrite = from: to: ''
    substituteInPlace $out/modern-web.mjs --replace-fail ${lib.escapeShellArg from} ${lib.escapeShellArg to}
  '';

  # Telemetry posts the search queries to Google's clearcut through a detached
  # watchdog process; this skill has no reason to phone home. Stubbed rather
  # than removed, so the bundle's own shape stays as upstream wrote it.
  telemetryGate = ''
    function isTelemetryEnabled() {
      const optOutSetting = process2.env.DISABLE_TELEMETRY?.toLowerCase();
      if (optOutSetting === "1" || optOutSetting === "true") {
        return false;
      }
      if (process2.env.NODE_TEST_CONTEXT !== void 0) {
        return false;
      }
      return true;
    }
  '';

  telemetryOff = "function isTelemetryEnabled() {\n  return false;\n}\n";
in
stdenvNoCC.mkDerivation {
  pname = "${pname}-skill";
  inherit version;

  src = fetchurl {
    url = "https://registry.npmjs.org/${pname}/-/${pname}-${version}.tgz";
    hash = "sha256-vXqmI60QcQqa1meP28wLiQyQPFT9ar/BJv9C3gHw5Xc=";
  };

  # The tarball also carries a second skill (chrome-extensions) and one plugin
  # manifest per agent (Claude, Codex, Cursor, Grok, Kimi, Gemini); every agent
  # here reads ~/.agents/skills, so only this skill is wanted.
  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r skills/${pname}/. $out/
    chmod -R u+w $out

    substituteInPlace $out/SKILL.md --replace-fail \
      ${lib.escapeShellArg npxSection} ${lib.escapeShellArg newSection}
    substituteInPlace $out/SKILL.md --replace-fail \
      ${lib.escapeShellArg proseFrom} ${lib.escapeShellArg proseTo}
    substituteInPlace $out/SKILL.md --replace-fail \
      ${lib.escapeShellArg npxPrefix} ${lib.escapeShellArg cli}

    # The skill runs the CLI with the node that built it, and without its
    # telemetry.
    substituteInPlace $out/modern-web.mjs \
      --replace-fail '#!/usr/bin/env node' '#!${lib.getExe' nodejs "node"}'

    ${rewrite telemetryGate telemetryOff}

    runHook postInstall
  '';

  meta = {
    description = "Chrome's modern web best-practice guides, built as an Agent Skill";
    homepage = "https://github.com/GoogleChrome/modern-web-guidance";
    license = lib.licenses.asl20;
    platforms = lib.platforms.unix;
  };
}
