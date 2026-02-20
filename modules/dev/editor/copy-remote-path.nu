#!/usr/bin/env nix-shell
#!nix-shell -i nu -p nushell jujutsu wl-clipboard

# Generates a remote git URL for the given file and line, and copies it to the clipboard.
def main [
  file: string # Absolute or relative path to the file
  --line-start (-s): string # The starting line number (e.g., cursor line)
  --line-end (-e): string # The ending line number (for selections)
] {
  let root = (jj workspace root | str trim)
  let rel_path = ($file | path expand | path relative-to $root)

  # Intersect current ancestry with the ancestry of all remote bookmarks
  let ref = (jj log -r "heads(::@ & ::remote_bookmarks())" -n 1 --no-graph -T "commit_id" | str trim)

  if ($ref | is-empty) {
    print -e "Error: No pushed commits found in the current ancestry."
    exit 1
  }

  let remote_url = (
    jj git remote list
    | parse "{remote} {url}"
    | where remote == "origin"
    | get url.0
    | if ($in | str contains "://") { $in } else { $"https://($in | str replace ':' '/')" }
    | url parse
  )

  # Construct the line number suffix (GitHub format)
  let start = if ($line_start | is-empty) { "" } else { $line_start }
  let end = if ($line_end | is-empty) { "" } else { $"-L($line_end)" }
  let line_suffix = if ($start | is-empty) { "" } else { $"#L($start)($end)" }

  # Construct the final URL
  let url = $"https://($remote_url.host)($remote_url.path | str replace '.git' '')/blob/($ref)/($rel_path)($line_suffix)"

  $url | wl-copy
  print -e $"Copied to clipboard: ($url)"
}
