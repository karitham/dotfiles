# The shared servers (./servers.nix) are declared in albedo's own shape already,
# so this only drops what albedo cannot use. Both callers need it: the restated
# servers in a home (./albedo.nix), and the image's extensions.json
# (./albedo-config.nix).
{ lib }: {
  # Albedo cannot put a variable inside a header value, so a server that names
  # its token variable sends it as `bearerTokenEnvVar` and loses that one
  # header; a header it can send as written stays. It has no OAuth settings
  # either: it starts its own sign-in when asked.
  toAlbedo =
    server:
    lib.filterAttrs (_: value: value != null && value != [ ] && value != { }) (
      removeAttrs server [ "oauth" ]
      // lib.optionalAttrs (server ? bearerTokenEnvVar) {
        headers = removeAttrs (server.headers or { }) [ "Authorization" ];
      }
    );
}
