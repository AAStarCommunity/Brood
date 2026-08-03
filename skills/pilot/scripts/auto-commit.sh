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
  main|master|develop|preview|integration|release*|hotfix*) echo "auto-commit: on protected '$branch' — skipping (checkpoints only on feature branches)"; exit 0 ;;
esac
# Honor the same configured protection as git-guard (PILOT_PROTECTED / old REPO_PILOT_PROTECTED
# fallback) so a repo with a custom trunk name doesn't get unattended `git add -A` checkpoints
# landing on trunk via auto-commit-loop.sh. Prefix match mirrors git-guard's is_protected.
_prot="${PILOT_PROTECTED:-${REPO_PILOT_PROTECTED:-}}"
if [ -n "$_prot" ]; then
  _oIFS="$IFS"; IFS=','
  for p in $_prot; do
    [ -n "$p" ] || continue
    case "$branch" in "$p"|"$p"[-_/.0-9]*) echo "auto-commit: on protected '$branch' (via PILOT_PROTECTED) — skipping"; exit 0 ;; esac
  done
  IFS="$_oIFS"
fi

# Nothing to do?
[ -n "$(git status --porcelain)" ] || { echo "auto-commit: clean working tree — nothing to commit"; exit 0; }

# Secret guard: if an UNTRACKED file being newly captured looks like a secret and isn't
# gitignored, STOP and warn rather than snapshotting it. (.gitignore is the primary defense.)
# Scan untracked-only: tracked files are already in git so re-snapshotting them leaks nothing,
# and this stops a tracked source path like lib/tokenizer.py from wholesale-disabling every
# checkpoint. `-z` (NUL-delimited) so paths with spaces/quotes (e.g. "cfg/prod key.pem") parse
# intact instead of being split by awk and slipping through. Matched against basename to avoid
# path-substring false positives.
# NOTE: read loop, NOT `mapfile` — mapfile is bash 4+ and macOS ships 3.2 as /bin/bash.
secret_re='(^\.env($|\.)|\.(pem|key|p12|pfx|keystore|asc)$|^\.(npmrc|netrc|pgpass)$|^(id_rsa|id_dsa|id_ecdsa|id_ed25519)$|^authorized_keys$|^known_hosts$|(^|[._-])(secret|secrets|credential|credentials|passwd|service-account)([._-]|$))'
risky=()
while IFS= read -r -d '' rf; do
  base="${rf##*/}"
  printf '%s' "$base" | grep -iqE "$secret_re" && risky+=("$rf")
done < <(git ls-files --others --exclude-standard -z)
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
