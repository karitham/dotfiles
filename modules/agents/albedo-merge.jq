# Merge the extensions.json fragment this flake builds into the extensions.json
# albedo owns. A server the fragment carries is added or kept current, one it
# carried last time but no longer does was deleted in the flake and goes too,
# and every other server, toggle and setting stays as albedo wrote it.
#
# Inputs: --slurpfile f <fragment>, --argjson before <names managed last time>.
def resolve:
  walk(if type == "string" and startswith("@env:")
       then (.[5:] as $name | (env[$name] // .))
       else . end);
def unresolved: [.. | strings | select(startswith("@env:"))] | length > 0;

($f[0] | resolve) as $frag
| ($frag.servers | with_entries(select(.value | unresolved | not))) as $servers
| ($servers | keys) as $owned
| ($before - $owned) as $gone
| .mcp = (.mcp // {})
| .mcp.servers = (
    ((.mcp.servers // {}) | with_entries(select(.key as $name | ($gone | index($name)) | not)))
    * $servers
  )
| .enabled = ((.enabled // {}) * ($frag.enabled // {}))
