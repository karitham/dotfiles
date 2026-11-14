# ozen runs under WSL with mirrored networking, so the distro shares Windows'
# loopback and reaches the Helium instance that is already open. Attach to it
# rather than letting the MCP start its own browser: the point is the logged-in
# session, not a blank profile.
#
# DevToolsActivePort is written by Helium at every launch and holds the CDP port
# on line 1 and /devtools/browser/<uuid> on line 2. The uuid changes on each
# start, so the path is read at connect time instead of pinned here.
{ pkgs, ... }: {
  dev.agents.attachBrowser = "/mnt/c/Users/kar/AppData/Local/imput/Helium/User Data/DevToolsActivePort";
  dev.gallant.local.enable = true;
  dev.albedo.enable = true;

  # The daemon the phone and the other machines pair with: it keeps running
  # after the desktop app closes, and answers on the tailnet. This machine has
  # no desktop app, so it takes the server-only package and leaves Electron out
  # of the closure (32 GiB against 2 GiB).
  dev.t3code.daemon = {
    enable = true;
    expose = true;
    package = pkgs.callPackage ../../pkgs/t3code-server/package.nix { };
  };
}
