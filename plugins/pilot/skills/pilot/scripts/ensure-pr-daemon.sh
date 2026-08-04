#!/usr/bin/env bash
# ensure-pr-daemon.sh — make sure the external PR-review daemon loop is running.
#
# pilot does NOT review its own PRs. A separate background daemon (PR-Daemon) polls
# the configured repos across the three orgs and posts APPROVE / REQUEST_CHANGES /
# COMMENT. That daemon runs as a detached `nohup` process, independent of any Claude
# conversation — so "waking it up" is just: start it if its PID is dead.
#
# This wrapper drives the daemon's OWN canonical entry point (watch.sh), which exports
# PR_DAEMON_AUTO_REVIEW=1 etc. It never stops or kills anything.
#
# Locate the daemon root via (first hit wins):
#   --root <path>  |  $PILOT_PR_DAEMON_ROOT  |  ~/Dev/tools/PR-Daemon
#
# Subcommands:
#   check           report running / not-running (exit 0=running, 3=down, 2=daemon-not-found)
#   ensure          (default) start it if down; no-op if already running (idempotent)
set -euo pipefail

root=""
sub="ensure"
while [ $# -gt 0 ]; do
  case "$1" in
    --root) [ $# -ge 2 ] || { echo "ERROR: --root needs a path" >&2; exit 2; }; root="$2"; shift 2 ;;
    check|ensure) sub="$1"; shift ;;
    *) shift ;;
  esac
done

[ -n "$root" ] || root="${PILOT_PR_DAEMON_ROOT:-${REPO_PILOT_PR_DAEMON_ROOT:-$HOME/Dev/tools/PR-Daemon}}"
watch="$root/watch.sh"

if [ ! -x "$watch" ] && [ ! -f "$watch" ]; then
  echo "PR_DAEMON: not found (no watch.sh at $root)"
  echo "  set \$PILOT_PR_DAEMON_ROOT or pass --root <path> if the daemon lives elsewhere."
  exit 2
fi

refresh_focus_daily() {
  # Once-per-day, IDEMPOTENT recompute of the daemon's scan list (top-N most-recently-
  # pushed repos + pinned). ANY repo's `pilot status` lands here, so the day's first
  # status refreshes the shared global list and every later call is a cheap no-op (the
  # date stamp lives in the daemon's config dir, not here). Best-effort + BOUNDED: a
  # slow/failed gh call must never block ensuring the daemon. Only reached from `ensure`
  # (a mutating path) — `check`/doctor stay strictly read-only and never trigger this.
  local focus="$root/scripts/refresh-scan-focus.sh"
  [ -x "$focus" ] || return 0
  [ "${PILOT_SKIP_FOCUS_REFRESH:-0}" = "1" ] && return 0
  local to="${PILOT_FOCUS_TIMEOUT:-45}" tmp="/tmp/pilot-focus.$$"
  "$focus" daily >"$tmp" 2>&1 &
  local p=$!
  ( sleep "$to"; kill -0 "$p" 2>/dev/null && kill "$p" 2>/dev/null ) &
  local w=$!
  if wait "$p" 2>/dev/null; then :; fi
  kill "$w" 2>/dev/null || true; wait "$w" 2>/dev/null || true
  grep -iE 'idempotent|recorded|wrote|repos|fail|timed' "$tmp" 2>/dev/null | head -2 | sed 's/^/  focus: /' || true
  rm -f "$tmp"
  return 0
}

is_running() {
  # Authoritative signal = the actual loop PROCESS. pgrep also avoids the SIGPIPE-under-
  # pipefail trap that `bash "$watch" status | grep -q` falls into (grep -q closes the pipe
  # early → watch.sh gets SIGPIPE → pipefail makes the pipeline rc=141 → false "not running").
  if command -v pgrep >/dev/null 2>&1; then
    pgrep -f 'review_watch\.py' >/dev/null 2>&1 && return 0
    return 1
  fi
  # No pgrep: capture first (no pipe) so grep can't SIGPIPE-kill watch.sh under pipefail.
  local out
  out="$(bash "$watch" status 2>/dev/null || true)"
  case "$out" in *'review watcher running'*) return 0 ;; *) return 1 ;; esac
}

case "$sub" in
  check)
    if is_running; then
      echo "PR_DAEMON: running"
      bash "$watch" status 2>/dev/null | grep -E 'running: pid|last_full_sync|meta:' | head -3 || true
      exit 0
    fi
    echo "PR_DAEMON: not running"
    exit 3
    ;;
  ensure)
    # Refresh the shared scan list first (idempotent/day), THEN ensure the daemon — so
    # even when the daemon is already up, today's list is current before we return.
    refresh_focus_daily
    if is_running; then
      echo "PR_DAEMON: already running — nothing to do (your PRs will be picked up)."
      exit 0
    fi
    echo "PR_DAEMON: down — starting the review watcher (detached background)…"
    # watch.sh start -> start_review_watch.sh start, with AUTO_REVIEW env set. Idempotent.
    # Capture first, THEN filter — piping a mutating `start` into `grep|head` lets head close
    # early and SIGPIPE-kill watch.sh mid-startup under pipefail (same hazard is_running avoids).
    start_out="$(bash "$watch" start 2>&1 || true)"
    printf '%s\n' "$start_out" | grep -E 'started review watcher|already running|pid ' | head -3 || true
    if is_running; then
      echo "PR_DAEMON: started ✓ — it now reviews open PRs across the configured repos."
      exit 0
    fi
    echo "PR_DAEMON: start attempted but watcher still not detected — check $root logs."
    exit 3
    ;;
esac
