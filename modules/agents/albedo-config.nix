# What albedo needs where home-manager does not run: the MCP servers every agent
# shares (./servers.nix) rendered into its extensions.json, the shared skills, and
# the script that installs both into a home. The flake exposes the pair as
# .#albedo-config and .#albedo-seed; the image built in the infra repo carries
# them and seeds its home volume before the daemon starts.
{
  lib,
  pkgs,
  self',
  # Servers the target cannot run at all, left out of its config rather than
  # carried switched off: the chrome-devtools MCP drives a browser, so an image
  # without one has no use for its 284 MiB of dependencies.
  without ? [ ],
}:
let
  render = import ./lib.nix { inherit lib; };

  servers = removeAttrs (import ./servers.nix { inherit lib pkgs self'; }) without;

  skills = import ./agent-skills.nix { inherit pkgs; };

  fragment = pkgs.writeText "albedo-extensions.json" (
    builtins.toJSON {
      servers = lib.mapAttrs (_: render.toAlbedo) servers;
      enabled.mcp = true;
    }
  );

  # etc/albedo, so `contents = [ albedo-config ]` in an image lands it at
  # /etc/albedo without renaming anything.
  config = pkgs.runCommandLocal "albedo-config" { } ''
    mkdir -p $out/etc/albedo
    cp ${fragment} $out/etc/albedo/extensions.json
    ln -s ${skills} $out/etc/albedo/skills
  '';
in
{
  inherit config;
  seed = import ./albedo-seed.nix {
    inherit lib pkgs;
    fragment = "${config}/etc/albedo/extensions.json";
    skills = "${config}/etc/albedo/skills";
  };
}
