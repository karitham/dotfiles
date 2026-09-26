{
  config,
  lib,
  pkgs,
  ...
}:
let
  tuicr-wrapper = pkgs.writeShellScriptBin "tuicr-wrapper-zellij" ''
    set -euo pipefail

    if [[ -z "''${ZELLIJ:-}" ]]; then
      echo "Error: not running inside zellij" >&2
      exit 1
    fi

    if [[ $# -lt 1 ]]; then
      echo "Usage: tuicr-wrapper-zellij <directory> [-- tuicr-args...]" >&2
      exit 1
    fi

    target_dir="$1"
    shift

    if [[ "''${1:-}" == "--" ]]; then
      shift
    fi

    if [[ $# -eq 0 ]]; then
      echo "Error: pass a scope after --, e.g. -- -w or -- -r main..HEAD" >&2
      exit 1
    fi

    if ! git -C "$target_dir" rev-parse --git-dir &>/dev/null \
      && ! command -v jj &>/dev/null; then
      echo "Error: not a git or jj repository: $target_dir" >&2
      exit 1
    fi

    direction="''${TUICR_PANE_DIRECTION:-right}"

    fifo=$(mktemp -u "/tmp/tuicr-fifo.XXXXXX")
    mkfifo "$fifo"

    output_file=""
    tuicr_cmd="tuicr"

    if tuicr --help 2>&1 | grep -q -- '--stdout'; then
      output_file=$(mktemp /tmp/tuicr-output.XXXXXX)
      tuicr_cmd="$tuicr_cmd --stdout > '$output_file'"
    fi

    zellij action new-pane \
      --direction "$direction" \
      --name "tuicr" \
      --close-on-exit \
      -- bash -c "cd '$target_dir' && $tuicr_cmd \$@; echo done > '$fifo'" \
      -- "$@"

    read -r _ < "$fifo"
    rm -f "$fifo"

    zellij action focus-previous-pane 2>/dev/null || true

    if [[ -n "$output_file" ]] && [[ -s "$output_file" ]]; then
      echo ""
      echo "=== TUICR INSTRUCTIONS ==="
      cat "$output_file"
      echo "=== END TUICR INSTRUCTIONS ==="
      rm -f "$output_file"
    fi
  '';
in
{
  config = lib.mkIf config.dev.enable {
    home.packages = [
      pkgs.tuicr
      tuicr-wrapper
    ];

    xdg.configFile."tuicr/config.toml".source = (pkgs.formats.toml { }).generate "tuicr-config.toml" {
      theme = "catppuccin-macchiato";
      comment_vim = true;
      scroll_offset = 5;
      no_update_check = true;
      editor = "hx";
    };
  };
}
