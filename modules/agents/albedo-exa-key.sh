# albedo_exa_key CREDS [RUNNER]
#
# Store the key in $EXA_API_KEY as albedo's `exa.apiKey` in CREDS, doing nothing
# when it is already there. Exa reads its key from creds.json and has no
# environment fallback, while every other section of that file belongs to
# albedo, so an unchanged key must not rewrite it under a running daemon.
#
# RUNNER optionally names a function to run the final move through, so the image
# seed can print its commands instead of applying them.
albedo_exa_key() {
  albedo_exa_creds="$1"
  albedo_exa_runner="${2:-}"

  [ -n "${EXA_API_KEY:-}" ] || return 0

  albedo_exa_saved="$(jq -r '.exa.apiKey // ""' "$albedo_exa_creds" 2>/dev/null || true)"
  [ "$albedo_exa_saved" = "$EXA_API_KEY" ] && return 0

  albedo_exa_work="$(mktemp -d)"
  if [ -r "$albedo_exa_creds" ]; then
    cp "$albedo_exa_creds" "$albedo_exa_work/creds.json"
  else
    printf '{}\n' > "$albedo_exa_work/creds.json"
  fi

  jq --arg key "$EXA_API_KEY" '.exa.apiKey = $key' "$albedo_exa_work/creds.json" > "$albedo_exa_work/next.json"
  chmod 600 "$albedo_exa_work/next.json"

  # The status survives the cleanup: a move that fails must not look like a key
  # that was written, and activation has nothing else to notice it by.
  if [ -n "$albedo_exa_runner" ]; then
    "$albedo_exa_runner" mv -f "$albedo_exa_work/next.json" "$albedo_exa_creds" || albedo_exa_status=$?
  else
    mv -f "$albedo_exa_work/next.json" "$albedo_exa_creds" || albedo_exa_status=$?
  fi

  rm -rf "$albedo_exa_work"
  return "${albedo_exa_status:-0}"
}
