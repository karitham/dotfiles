#!/usr/bin/env -S nu --no-config-file
# we assume jj & nushell & libnotify are in path

def main [] {
  let now = (date now)
  let date_path = ($now | format date "%Y/%m")
  let day_file = ($now | format date "%d.md")
  let log_dir = $"($env.HOME)/notes/logs/($date_path)"

  mkdir $log_dir

  let target = ($log_dir | path join $day_file)
  run-external $env.EDITOR $target

  cd $log_dir

  jj describe -m $"Log update: ($now | format date '%F %T')"
  jj bookmark set main -r @
  jj git push -b main

  notify-send 'Log Synced' 'Updates pushed to git.'
}
