#!/usr/bin/env nix-shell
#!nix-shell -i nu -p nushell jujutsu libnotify

def main [] {
  let now = (date now)
  let log_dir = $"($env.HOME)/notes/logs/($now | format date "%Y/%m")"

  if not ($log_dir | path exists) { mkdir $log_dir }

  cd $log_dir

  run-external $env.EDITOR $"($now | format date "%d").md"

  job spawn {
    do {
      let msg = $"Log update: ($now | format date '%F %T')"

      if (jj log --no-graph -r $"@- & files\('logs')" | is-not-empty) {
        jj squash --ignore-immutable --message $msg
        jj bookmark set main -r @-
        jj git push -b main
      } else {
        jj describe -m $msg
        jj bookmark set main -r @
        jj git push -b main
      }

      notify-send "Log Synced" $"Updates pushed to git.\n($msg)"
    } | complete
  } | ignore
}
