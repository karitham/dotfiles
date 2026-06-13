#!/usr/bin/env -S nu --no-config-file
#
# Generates a remote git URL for the given file and line, and copies it to the clipboard.
# Requires `jj`, `nu`, and a clipboard command (`wl-copy` by default) to be available.
# Set COPY_REMOTE_PATH_CLIPBOARD to use a different clipboard command.
def clipboard-copy [text: string] {
    let cmd = $env.COPY_REMOTE_PATH_CLIPBOARD? | default "wl-copy"
    $text | run-external $cmd
}

def main [
  file: string # Absolute or relative path to the file
  --line-start (-s): string # The starting line number (e.g., cursor line)
  --line-end (-e): string # The ending line number (for selections)
] {

    # Spawn independent jj queries in parallel; each sends its result back to the main thread.
    job spawn { (jj workspace root | str trim) | job send --tag 1 0 }
    job spawn { (jj log -r "heads(::@ & ::remote_bookmarks('*', 'origin'))" -n 1 --no-graph -T "commit_id" | str trim) | job send --tag 2 0 }
    job spawn { (jj git remote list) | job send --tag 3 0 }

    let root = job recv --tag 1
    let ref = job recv --tag 2
    let remote_list = job recv --tag 3

    let rel_path = $file | path expand | path relative-to $root

    if ($ref | is-empty) {
        print -e "Error: No pushed commits found in the current ancestry."
        exit 1
    }

    let remote_url = (
        $remote_list | lines | parse "{remote} {url}" | where remote == "origin" | get url.0 | if ($in | str contains "://") { $in } else { $"https://($in | str replace ':' '/')" } | url parse
    )
    # Construct the line number suffix (GitHub format)
    let start = if ($line_start | is-empty) { "" } else { $line_start }
    let end = if ($line_end | is-empty) { "" } else { $"-L($line_end)" }
    let line_suffix = if ($start | is-empty) { "" } else { $"#L($start)($end)" }
    # Construct the final URL
    let url = $"https://($remote_url.host)($remote_url.path | str replace '.git' '')/blob/($ref)/($rel_path)($line_suffix)"
    clipboard-copy $url
    print -e $"Copied to clipboard: ($url)"
}
