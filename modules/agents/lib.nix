# One neutral MCP server shape, rendered into each agent's own config format.
# ./mcp.nix and any tag module declare a server once; opencode and albedo are
# both generated from that same set.
{ lib }:
let
  # A header or environment value is a literal, or a reference to a variable
  # the agent resolves when it connects.
  toOpencodeSource = value: if builtins.isString value then value else "{env:${value.env}}";
  toAlbedoSource = value: if builtins.isString value then value else { env = value.env; };
in
{
  # One entry of `mcp.servers` in ~/.config/opencode/opencode.json.
  toOpencode =
    server:
    if server.type == "http" then
      let
        headers =
          lib.mapAttrs (_: toOpencodeSource) server.headers
          // lib.optionalAttrs (server.bearerEnv != null) { Authorization = "Bearer {env:${server.bearerEnv}}"; };
      in
      {
        type = "remote";
        url = if server.urlEnv != null then "{env:${server.urlEnv}}" else server.url;
      }
      // lib.optionalAttrs (headers != { }) { inherit headers; }
      // lib.optionalAttrs (server.oauth != null) { inherit (server) oauth; }
      // lib.optionalAttrs (!server.enabled) { disabled = true; }
      // lib.optionalAttrs (server.timeoutMs != null) { timeout = server.timeoutMs; }
    else
      {
        type = "local";
        command = server.command;
      }
      // lib.optionalAttrs (server.env != { }) { environment = lib.mapAttrs (_: toOpencodeSource) server.env; }
      // lib.optionalAttrs (server.cwd != null) { inherit (server) cwd; }
      // lib.optionalAttrs (!server.enabled) { disabled = true; }
      // lib.optionalAttrs (server.timeoutMs != null) { timeout = server.timeoutMs; };

  # One entry of `mcp.servers` in $ALBEDO_HOME/extensions.json. `enabled` is
  # only written when it is off: albedo reads a missing one as on, so a server
  # switched off from albedo's own UI survives the next activation.
  #
  # A URL cannot reference a variable here, so `urlEnv` becomes an `@env:NAME@`
  # sentinel that ./albedo.nix substitutes from the decrypted secrets.
  toAlbedo =
    server:
    if server.type == "http" then
      {
        type = "http";
        url = if server.urlEnv != null then "@env:${server.urlEnv}" else server.url;
      }
      // lib.optionalAttrs (server.headers != { }) { headers = lib.mapAttrs (_: toAlbedoSource) server.headers; }
      // lib.optionalAttrs (server.bearerEnv != null) { bearerTokenEnvVar = server.bearerEnv; }
      // lib.optionalAttrs (!server.enabled) { enabled = false; }
      // lib.optionalAttrs (server.timeoutMs != null) { callTimeoutMs = server.timeoutMs; }
      // lib.optionalAttrs (server.startupTimeoutMs != null) { inherit (server) startupTimeoutMs; }
    else
      {
        type = "stdio";
        command = lib.head server.command;
      }
      // lib.optionalAttrs (lib.length server.command > 1) { args = lib.tail server.command; }
      // lib.optionalAttrs (server.env != { }) { env = lib.mapAttrs (_: toAlbedoSource) server.env; }
      // lib.optionalAttrs (server.cwd != null) { inherit (server) cwd; }
      // lib.optionalAttrs (!server.enabled) { enabled = false; }
      // lib.optionalAttrs (server.timeoutMs != null) { callTimeoutMs = server.timeoutMs; }
      // lib.optionalAttrs (server.startupTimeoutMs != null) { inherit (server) startupTimeoutMs; };
}
