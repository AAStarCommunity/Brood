#!/usr/bin/env bash
# check-hooks.sh — verify this repo's git hooks are ACTUALLY active, not a silent no-op.
#
# Real-world failure this catches: core.hooksPath pointing at ANOTHER clone's hooks dir
# (or an empty dir) means the pre-commit secret scan never runs — commits go unprotected
# and nobody notices. pilot must never *assume* commit protection works; it verifies.
#
# REPORT ONLY — never rewires hooks. Re-enabling a noisy scanner can lock up commits
# (historical false positives), so wiring is a human decision: reduce noise first, then wire.
#
# Exit: 0 = hooks OK (or repo has none by design), 3 = misconfigured/bypassed, 2 = not a repo.
set -euo pipefail

top="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "HOOKS: not a git repo"; exit 2; }

hp_raw="$(git config --get core.hooksPath || true)"
if [ -n "$hp_raw" ]; then
  case "$hp_raw" in /*) hp="$hp_raw" ;; *) hp="$top/$hp_raw" ;; esac   # git resolves relative to top
  configured=1
else
  hp="$(git rev-parse --git-path hooks)"
  case "$hp" in /*) : ;; *) hp="$top/$hp" ;; esac
  configured=0
fi
hp_abs="$(cd "$hp" 2>/dev/null && pwd || echo "$hp")"

# Is the active hooks dir inside THIS repo?
case "$hp_abs/" in "$top/"*) inside=1 ;; *) inside=0 ;; esac

# Active pre-commit present + executable?
if [ -f "$hp_abs/pre-commit" ] && [ -x "$hp_abs/pre-commit" ]; then has_pc=1; else has_pc=0; fi

# Does the repo SHIP a pre-commit hook that isn't the active one?
shipped=""
for d in "$top/.githooks" "$top/hooks"; do
  [ -f "$d/pre-commit" ] && { shipped="$d"; break; }
done

problem=0
if [ "$inside" = "0" ]; then
  echo "HOOKS: ⚠️ BYPASSED — core.hooksPath points OUTSIDE this repo:"
  echo "  active hooks dir = $hp_abs"
  echo "  this repo        = $top"
  echo "  → pre-commit protection (secret scan etc.) is NOT running on commits here."
  problem=1
elif [ "$has_pc" = "0" ]; then
  if [ -n "$shipped" ]; then
    echo "HOOKS: ⚠️ repo ships $shipped/pre-commit but it is NOT active (active dir $hp_abs has no executable pre-commit)."
    problem=1
  else
    echo "HOOKS: ok — no pre-commit hook active and none shipped (repo doesn't use one)."
  fi
else
  echo "HOOKS: ✓ pre-commit active at $hp_abs"
fi

if [ "$problem" = "1" ] && [ -n "$shipped" ]; then
  echo "  repo's intended hooks: $shipped"
  echo "  DO NOT auto-wire. If the scanner has historical false positives, re-enabling will"
  echo "  make every commit fail. Reduce noise (baseline/allowlist the known FPs) FIRST, then:"
  echo "    git config core.hooksPath ${shipped#$top/}"
fi

[ "$problem" = "1" ] && exit 3
exit 0
