# ozen runs under WSL with mirrored networking, so the distro shares Windows'
# loopback and reaches the Helium instance that is already open. Attach to it
# rather than letting the MCP start its own browser: the point is the logged-in
# session, not a blank profile.
#
# DevToolsActivePort is written by Helium at every launch and holds the CDP port
# on line 1 and /devtools/browser/<uuid> on line 2. The uuid changes on each
# start, so the path is read at connect time instead of pinned here.
{ ... }: { dev.opencode.attachBrowser = "/mnt/c/Users/kar/AppData/Local/imput/Helium/User Data/DevToolsActivePort"; }
