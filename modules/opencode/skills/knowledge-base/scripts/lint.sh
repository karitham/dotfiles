#!/usr/bin/env bash
# Deterministic health check for the ~/notes/wiki knowledge base.
# Usage: lint.sh [wiki-dir]   (default: ~/notes/wiki)
# Exit 0 = pass. Hard failures: frontmatter, log format, broken links,
# index coverage. Warnings (non-fatal): orphan pages.

set -uo pipefail
WIKI="${1:-$HOME/notes/wiki}"
fail=0

[ -d "$WIKI" ] || { echo "FAIL: no wiki at $WIKI"; exit 1; }

# --- frontmatter on every content page ---
while IFS= read -r f; do
  [ "$(head -n1 "$f")" = "---" ] || { echo "FAIL: missing frontmatter: ${f#$WIKI/}"; fail=1; }
done < <(find "$WIKI" -name '*.md' ! -name 'index.md' ! -name 'log.md')

# --- log entry format ---
if ! grep -qE '^## \[[0-9]{4}-[0-9]{2}-[0-9]{2}\] (record|ingest|query|lint) \| \[[^]]+\] .' \
    "$WIKI/log.md" 2>/dev/null; then
  echo "FAIL: no well-formed entries in log.md"
  fail=1
fi

# --- wikilinks resolve ---
link_names="$(grep -rohE '\[\[[^]|]+' "$WIKI" --include='*.md' \
  | sed 's/^\[\[//' | sort -u)"
while IFS= read -r name; do
  [ -z "$name" ] && continue
  if [ -z "$(find "$WIKI" -name "$name.md" -print -quit)" ]; then
    echo "FAIL: broken link target: [[$name]]"
    fail=1
  fi
done <<< "$link_names"

# --- index coverage ---
while IFS= read -r f; do
  name="$(basename "$f" .md)"
  grep -q "\[\[$name\]\]" "$WIKI/index.md" \
    || { echo "FAIL: not in index.md: $name"; fail=1; }
done < <(find "$WIKI" -name '*.md' ! -name 'index.md' ! -name 'log.md')

# --- orphans (warning only) ---
while IFS= read -r f; do
  name="$(basename "$f" .md)"
  case "$name" in index|log) continue;; esac
  if ! grep -rqF "[[$name]]" "$WIKI" --include='*.md' \
      --exclude="$name.md" --exclude='log.md'; then
    echo "WARN: orphan page (no inbound links): $name"
  fi
done < <(find "$WIKI" -name '*.md' ! -name 'index.md' ! -name 'log.md')

[ "$fail" -eq 0 ] && echo "LINT: PASS ($WIKI)" || echo "LINT: FAIL ($WIKI)"
exit "$fail"
