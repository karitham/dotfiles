# The MCP servers every agent on this host is given, in home-manager's
# `programs.mcp.servers` shape. ./mcp.nix hands them to `programs.mcp`, which
# writes them for the clients that read ~/.config/mcp/mcp.json and feeds both
# agents' own integrations; ./albedo-config.nix renders the same set into the
# image that home-manager never configures.
#
# Each entry is written so albedo can take it as-is (./lib.nix only drops the two
# fields it has no use for), which means `type` is spelled out: opencode
# recomputes it, albedo reads it.
#
# A tag module adds a host's own servers with
# `programs.mcp.servers.<name> = { ... };` — there is no wrapper option.
{
  lib,
  pkgs,
  self',
  # Browser the chrome-devtools MCP drives, passed as --executablePath. Null
  # leaves the flag off and lets the server look for a Chrome itself.
  mcpBrowser ? null,
  # DevToolsActivePort file of a browser that is already running, as a path this
  # machine can read: the server attaches to it over CDP instead of launching
  # one, so the agent sees the tabs and logged-in sessions of the user's own
  # profile.
  attachBrowser ? null,
  # Include the servers that need a secret from the environment. A host that
  # holds the secrets itself says so here; the ones without keep them declared
  # and switched off.
  secretServers ? true,
}:
let
  chrome-devtools-mcp = lib.getExe self'.packages.chrome-devtools-mcp;
  sed = lib.getExe' pkgs.coreutils "sed";

  # DevToolsActivePort holds the CDP port on line 1 and /devtools/browser/<uuid>
  # on line 2. Chromium serves no /json/version on that implicit endpoint, so
  # the server needs --wsEndpoint rather than --browserUrl, and it must read the
  # file at connect time because the uuid changes on every browser start.
  attachScript = ''
    f=${lib.escapeShellArg attachBrowser}
    exec ${chrome-devtools-mcp} --wsEndpoint "ws://127.0.0.1:$(${sed} -n 1p "$f")$(${sed} -n 2p "$f")"
  '';
in
{
  # No secret, so always available.
  outline = {
    type = "http";
    url = "https://outline.dolly-ruffe.ts.net/mcp";
  };

  # Off unless a host points it at a running browser: the fallback branch
  # launches one, which is a blank profile and no sessions.
  chrome-devtools = {
    type = "stdio";
    enabled = attachBrowser != null;
    command = if attachBrowser != null then lib.getExe pkgs.bash else chrome-devtools-mcp;
    args =
      if attachBrowser != null then
        [
          "-lc"
          attachScript
        ]
      else
        lib.optionals (mcpBrowser != null) [
          "--executablePath"
          (lib.getExe mcpBrowser)
        ];
  };
}
// lib.optionalAttrs secretServers {
  # These need a secret from the environment, so they only appear where the host
  # has one to give. Each names its token twice because the clients disagree on
  # the form: opencode sends the header, albedo reads the variable out of the
  # daemon's environment and cannot put a variable inside a header value at all,
  # so `bearerTokenEnvVar` is also the mark for the servers ./lib.nix strips.
  github = {
    type = "http";
    url = "https://api.githubcopilot.com/mcp/";
    headers.Authorization = "Bearer {env:GITHUB_TOKEN}";
    bearerTokenEnvVar = "GITHUB_TOKEN";
  };

  kagi = {
    type = "http";
    url = "https://mcp.kagi.com/mcp";
    headers.Authorization = "Bearer {env:KAGI_API_KEY}";
    bearerTokenEnvVar = "KAGI_API_KEY";
    # The key is the credential; an OAuth probe only gets in the way.
    oauth = false;
    enabled = false;
  };
}
