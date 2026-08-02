#!/usr/bin/env bash
# followups.sh — durable, append-only follow-up ledger for pilot.
#
# WHY: review comments classified "B (real but non-blocking)" — and any non-trivial
# deferred item — must NOT be lost and must NOT be done mid-stream. They are recorded
# here, then batched into ONE cleanup PR AFTER all primary tasks are done. The ledger
# is a COMMITTED file in the repo, so it survives across conversations/loops/machines
# and is visible to humans. GitHub PR comments remain the ultimate backstop.
#
# The ledger is a GitHub-flavored task list (renders on GitHub, greppable in shell):
#   - [ ] FU-3 · B · src=PR#13 · 2026-08-01 · <desc>          (OPEN)
#   - [x] FU-2 · D · src=PR#13 · 2026-08-01 · <desc> · done=PR#20   (DONE)
# Append-only: never delete a line; `done` flips [ ]→[x] in place and appends done=PR#n.
#
# Subcommands:
#   add   --class <A|B|C|D> --source <ref> --desc <text> [--docs-dir <dir>]   -> prints FU-<n>
#   list  [--open] [--docs-dir <dir>]
#   count-open [--docs-dir <dir>]
#   done  <FU-n> --pr <n> [--docs-dir <dir>]
#
# --docs-dir defaults to docs/agent (matches .pilot.yml docs_dir). Ledger = <docs-dir>/followups.md
set -euo pipefail

docs_dir="docs/agent"
cls=""; source_ref=""; desc=""; pr=""; only_open=0
sub="${1:-}"; [ $# -gt 0 ] && shift
pos=""
while [ $# -gt 0 ]; do
  case "$1" in
    --docs-dir) [ $# -ge 2 ] || { echo "ERROR: --docs-dir needs a value" >&2; exit 2; }; docs_dir="$2"; shift 2 ;;
    --class)    [ $# -ge 2 ] || { echo "ERROR: --class needs a value" >&2; exit 2; }; cls="$2"; shift 2 ;;
    --source)   [ $# -ge 2 ] || { echo "ERROR: --source needs a value" >&2; exit 2; }; source_ref="$2"; shift 2 ;;
    --desc)     [ $# -ge 2 ] || { echo "ERROR: --desc needs a value" >&2; exit 2; }; desc="$2"; shift 2 ;;
    --pr)       [ $# -ge 2 ] || { echo "ERROR: --pr needs a value" >&2; exit 2; }; pr="$2"; shift 2 ;;
    --open)     only_open=1; shift ;;
    -*)         echo "ERROR: unknown flag '$1'" >&2; exit 2 ;;
    *)          pos="$1"; shift ;;
  esac
done

ledger="$docs_dir/followups.md"

ensure_ledger() {
  if [ ! -f "$ledger" ]; then
    mkdir -p "$docs_dir"
    {
      echo "# Follow-ups ledger（append-only · 永不删行 · 提交进仓库）"
      echo
      echo "> pilot 的 review triage 把「真问题但不阻塞（B）」和延后项记在这里。"
      echo "> 主线 task 全部完成后，由 \`pilot run\` 批量合成一个 cleanup PR 做掉，逐条标 [x] done=PR#n。"
      echo "> \`- [ ]\`=OPEN，\`- [x]\`=DONE。GitHub PR comment 是永久兜底。"
      echo
    } > "$ledger"
  fi
}

next_id() {
  local n
  n="$(grep -oE 'FU-[0-9]+' "$ledger" 2>/dev/null | grep -oE '[0-9]+' | sort -n | tail -1 || true)"
  echo $(( ${n:-0} + 1 ))
}

lock_dir="$ledger.lock"
acquire_lock() {
  # mkdir is atomic → a portable mutex (macOS ships no flock). Serialize read-then-write so
  # concurrent `add`s can't compute the same next id (observed: 6 parallel adds → all FU-1),
  # and a `done` can't race a concurrent write of the ledger.
  mkdir -p "$docs_dir"
  local i=0
  until mkdir "$lock_dir" 2>/dev/null; do
    i=$((i+1)); [ "$i" -gt 300 ] && { echo "ERROR: cannot acquire $lock_dir (stale lock? rm it)" >&2; exit 3; }
    sleep 0.05
  done
  trap 'rmdir "$lock_dir" 2>/dev/null || true' EXIT
}

case "$sub" in
  add)
    [ -n "$cls" ] && [ -n "$desc" ] || { echo "usage: followups.sh add --class <A|B|C|D> --source <ref> --desc <text>" >&2; exit 2; }
    case "$cls" in A|B|C|D) : ;; *) echo "ERROR: --class must be A|B|C|D" >&2; exit 2 ;; esac
    acquire_lock          # serialize next_id-then-append so parallel adds get distinct ids
    ensure_ledger
    id="FU-$(next_id)"
    day="$(date +%F)"
    src="${source_ref:-manual}"
    # strip pipes/newlines from desc to keep one line
    desc_clean="$(printf '%s' "$desc" | tr '\n' ' ' | tr -d '\r')"
    printf -- '- [ ] %s · %s · src=%s · %s · %s\n' "$id" "$cls" "$src" "$day" "$desc_clean" >> "$ledger"
    echo "$id"
    ;;
  list)
    [ -f "$ledger" ] || { echo "(no ledger at $ledger)"; exit 0; }
    if [ "$only_open" = "1" ]; then
      grep -E '^- \[ \] FU-' "$ledger" || echo "(no open follow-ups)"
    else
      grep -E '^- \[[ x]\] FU-' "$ledger" || echo "(ledger empty)"
    fi
    ;;
  count-open)
    if [ -f "$ledger" ]; then grep -cE '^- \[ \] FU-' "$ledger" || echo 0; else echo 0; fi
    ;;
  done)
    [ -n "$pos" ] || { echo "usage: followups.sh done <FU-n> --pr <n>" >&2; exit 2; }
    [ -n "$pr" ] || { echo "ERROR: done requires --pr <n>" >&2; exit 2; }
    [ -f "$ledger" ] || { echo "ERROR: no ledger at $ledger" >&2; exit 2; }
    case "$pos" in FU-[0-9]*) : ;; *) echo "ERROR: id must look like FU-<n>" >&2; exit 2 ;; esac
    acquire_lock          # serialize read-modify-write of the ledger against concurrent add/done
    tmp="$ledger.tmp.$$"
    awk -v id="$pos" -v pr="$pr" '
      $0 ~ ("^- \\[ \\] " id " ") && index($0, "["id"") == 0 {
        # match the exact FU id token (avoid FU-1 matching FU-12)
      }
      {
        # exact-token match: line has "] <id> ·"
        if ($0 ~ ("^- \\[ \\] " id " · ")) {
          sub(/^- \[ \]/, "- [x]", $0)
          $0 = $0 " · done=PR#" pr
        }
        print
      }
    ' "$ledger" > "$tmp"
    if cmp -s "$ledger" "$tmp"; then rm -f "$tmp"; echo "ERROR: $pos not found or already done" >&2; exit 1; fi
    mv "$tmp" "$ledger"
    echo "marked $pos done (PR#$pr)"
    ;;
  *)
    echo "followups.sh: add | list [--open] | count-open | done <FU-n> --pr <n>" >&2
    exit 2 ;;
esac
