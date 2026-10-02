#!/usr/bin/env bash
# Shell entrypoint for OpenCode 2's shell tool, confined in a systemd user scope.
#
# OpenCode invokes the configured shell as `<shell> -c <command>`. We forward the
# argv verbatim to a real shell, but wrap the whole thing in `systemd-run --user
# --scope` so the command runs in its own cgroup. That gives two properties the
# plain shell lacks:
#
#   * OOM confinement. The scope has its own memory.high/memory.max, and systemd
#     raises the scope tasks' oom_score_adj, so a runaway command is OOM-killed
#     inside its own cgroup instead of killing the OpenCode process or competing
#     system-wide.
#   * Soft CPU weight. Under contention the scope gets a reduced share; when the
#     machine is idle it still uses every core. This is not a hard throttle, so
#     legitimate parallel builds do not silently slow down.
#
# Killing the client (what OpenCode does on timeout) propagates to the scope, and
# because we `exec` the wrapper's pid is the scope unit's pid, so the unit name is
# deterministic (`ocscope-<pid>`) and reachable via `systemctl --user stop`.
#
# Requirements: a working `systemd --user` session on Linux. When it is missing
# (plain SSH without linger, some containers) the wrapper falls back to running
# the command unconfined rather than failing every shell call.
set -euo pipefail

# Real shell to execute inside the scope. $SHELL is OpenCode's own environment,
# which the opencode wrapper sets to bash; keep an explicit fallback for the case
# where this script is invoked outside that wrapper.
REAL_SHELL=${OPENCODE_SCOPED_SHELL:-${SHELL:-/bin/sh}}

# Memory policy. memory.high is a soft limit: the kernel reclaims and throttles
# the cgroup before anything is killed. memory.max is the hard backstop. Swap is
# disabled so a runaway cannot thrash the machine into a system-wide stall.
# 2 GiB fits a single shell command on any machine this runs on; raise memory.high
# for larger builds at the cost of isolation.
MEMORY_HIGH=${OPENCODE_SCOPE_MEMORY_HIGH:-1536M}
MEMORY_MAX=${OPENCODE_SCOPE_MEMORY_MAX:-2048M}

# 100 is the systemd default; 20 gives the scope roughly one fifth of a normal
# task's weight under contention.
CPU_WEIGHT=${OPENCODE_SCOPE_CPU_WEIGHT:-20}

# Fall back to an unconfined shell when the user manager is unreachable. The
# check is cheap relative to a DBus call and keeps this usable over bare SSH.
if ! systemctl --user is-system-running >/dev/null 2>&1; then
  exec "$REAL_SHELL" "$@"
fi

exec systemd-run --user --scope --quiet --collect \
  --unit="ocscope-$$" \
  -p "MemoryHigh=${MEMORY_HIGH}" \
  -p "MemoryMax=${MEMORY_MAX}" \
  -p MemorySwapMax=0 \
  -p "CPUWeight=${CPU_WEIGHT}" \
  -- "$REAL_SHELL" "$@"
