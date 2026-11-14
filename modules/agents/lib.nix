# Albedo's own shape for the shared servers (./servers.nix), for a home that no
# home-manager runs in (./albedo-config.nix). A home-manager home needs none of
# it: albedo's module reads the same servers from `programs.mcp.servers` and
# makes the same translation.
{ lib }:
let
  # A token named inside the header, as every other client spells it. Albedo has
  # no header templating, so the header becomes the bearerTokenEnvVar it reads
  # from the daemon's environment and stops being a header.
  bearerPattern = "[Bb]earer [{]env:([A-Za-z_][A-Za-z0-9_]*)[}]";
  isBearer = value: builtins.isString value && builtins.match bearerPattern value != null;
  bearer =
    server:
    let
      headers = server.headers or { };
      named = lib.filter (name: lib.toLower name == "authorization" && isBearer headers.${name}) (lib.attrNames headers);
    in
    if named == [ ] then
      null
    else
      {
        name = builtins.head named;
        variable = builtins.head (builtins.match bearerPattern headers.${builtins.head named});
      };
in
{
  toAlbedo =
    server:
    let
      token = bearer server;
      # Everything the header carried moves to bearerTokenEnvVar, so the one
      # header albedo cannot send as written is the one it drops. It has no
      # OAuth settings either: it starts its own sign-in when asked.
      headers = removeAttrs (server.headers or { }) (lib.optional (token != null) token.name);
    in
    lib.filterAttrs (_: value: value != null && value != [ ] && value != { }) (
      removeAttrs server [
        "oauth"
        "headers"
      ]
      // lib.optionalAttrs (headers != { }) { inherit headers; }
      // lib.optionalAttrs (token != null) { bearerTokenEnvVar = token.variable; }
    );
}
