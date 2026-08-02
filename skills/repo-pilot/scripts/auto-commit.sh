#!/usr/bin/env bash
# auto-commit.sh — WIP safety checkpoints so untracked/uncommitted work is NEVER lost.
# (Born from a real incident: hardened, untracked scripts were deleted with no git copy.)
#
# Runs ONE check. Commits a checkpoint of the whole working tree when ANY trigger fires:
#   • 定量-files : > $MAX_FILES changed files (tracked-modified + untracked, .gitignore honored)
#   • 定量-lines : a single file has > $MAX_LINES changed/added lines
#   • 定时       : >= $INTERVAL seconds since the last commit AND there are changes
#
# Safety: stages with `git add -A` (so untracked legit files ARE captured — that's the point),
# but .gitignore is honored AND a secret-pattern guard refuses to stage .env / keys / tokens even
# if they slipped past .gitignore. Checkpoints use a `chore(wip):` message — squash them later.
#
# Env overrides: PILOT_AUTOCOMMIT_{INTERVAL,MAX_FILES,MAX_LINES}. Never pushes; never touches main.
set -euo pipefail

INTERVAL="${PILOT_AUTOCOMMIT_INTERVAL:-600}"     # 10 min
MAX_FILES="${PILOT_AUTOCOMMIT_MAX_FILES:-3}"     # > this many files -> commit now
MAX_LINES="${PILOT_AUTOCOMMIT_MAX_LINES:-200}"   # a single file changing > this -> commit now

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "auto-commit: not a git repo" >&2; exit 2; }
cd "$(git rev-parse --show-toplevel)"

# Refuse to run on protected branches — checkpoints belong on feature/WIP branches, not main.
branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo)"
case "$branch" in
  main|master|preview|integration|release*|hotfix*) echo "auto-commit: on protected '$branch' — skipping (checkpoints only on feature branches)"; exit 0 ;;
esac

# Nothing to do?
[ -n "$(git status --porcelain)" ] || { echo "auto-commit: clean working tree — nothing to commit"; exit 0; }

# Secret guard: if a would-be-staged file looks like a secret and isn't gitignored, STOP and warn
# rather than snapshotting it. (.gitignore is the primary defense; this is belt-and-suspenders.)
secretish='(^|/)\.env($|\.)|\.(pem|key|p12|pfx|keystore)$|(secret|token|credential|password)'
mapfile -t risky < <(git status --porcelain --untracked-files=all | awk '{print $2}' | grep -iE "$secretish" || true)
if [ "${#risky[@]}" -gt 0 ]; then
  echo "auto-commit: REFUSING — secret-looking files would be staged; .gitignore them first:" >&2
  printf '  %s\n' "${risky[@]}" >&2
  exit 3
fi

changed_files="$(git status --porcelain | wc -l | tr -d ' ')"

# Largest single-file change: modified files via numstat, untracked via line count.
max_single=0
while read -r add del _; do
  [ "$add" = "-" ] && continue    # binary
  tot=$(( add + del ))
  [ "$tot" -gt "$max_single" ] && max_single="$tot"
done < <(git diff --numstat HEAD 2>/dev/null; git diff --numstat 2>/dev/null)
while IFS= read -r f; do
  [ -f "$f" ] || continue
  n="$(wc -l < "$f" 2>/dev/null || echo 0)"
  [ "$n" -gt "$max_single" ] && max_single="$n"
done < <(git ls-files --others --exclude-standard)

last="$(git log -1 --format=%ct 2>/dev/null || echo 0)"
now="$(date +%s)"
age=$(( now - last ))

reasons=()
[ "$changed_files" -gt "$MAX_FILES" ] && reasons+=("$changed_files files (>$MAX_FILES)")
[ "$max_single" -gt "$MAX_LINES" ]   && reasons+=("${max_single}-line single-file change (>$MAX_LINES)")
[ "$age" -ge "$INTERVAL" ]           && reasons+=("${age}s since last commit (>=${INTERVAL})")

if [ "${#reasons[@]}" -eq 0 ]; then
  echo "auto-commit: no trigger ($changed_files files, max $max_single-line change, ${age}s idle) — skip"
  exit 0
fi

reason="$(IFS='; '; echo "${reasons[*]}")"
git add -A
git commit -q -m "chore(wip): auto-commit checkpoint — $reason

Safety checkpoint (squash before merge). Triggered by pilot auto-commit."
echo "auto-commit: ✓ checkpoint committed on '$branch' — $reason"
