#!/usr/bin/env bash
# install.sh — install pilot as a skill for Claude Code and/or Codex.
#
# The canonical source is THIS directory. By default it symlinks the skill into
# your agent's global skills dir, so editing the source updates every install
# (the skill docs are continuously maintained). Use --copy for a detached copy
# (e.g. installing on another machine from a download).
#
# Usage:
#   ./install.sh                      # Claude Code global (~/.claude/skills), symlink
#   ./install.sh --claude             # same, explicit
#   ./install.sh --codex              # Codex global (~/.codex/skills), symlink
#   ./install.sh --both               # Claude Code + Codex
#   ./install.sh --project /path/repo # into repo's .claude/skills AND .agents/skills
#   ./install.sh --copy   [target...] # copy instead of symlink
#   ./install.sh --uninstall [target...]
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NAME="pilot"

mode="link"          # link | copy
do_claude=0; do_codex=0; project=""; uninstall=0

while [ $# -gt 0 ]; do
  case "$1" in
    --claude) do_claude=1; shift ;;
    --codex)  do_codex=1; shift ;;
    --both)   do_claude=1; do_codex=1; shift ;;
    --project) project="${2:?--project needs a path}"; shift 2 ;;
    --copy)   mode="copy"; shift ;;
    --link)   mode="link"; shift ;;
    --uninstall) uninstall=1; shift ;;
    -h|--help) grep '^#' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done
# Default target: Claude Code global.
[ "$do_claude" = 0 ] && [ "$do_codex" = 0 ] && [ -z "$project" ] && do_claude=1

place() {  # place <target-dir>
  local dest_parent="$1" dest="$1/$NAME"
  mkdir -p "$dest_parent"
  if [ "$uninstall" = 1 ]; then
    if [ -L "$dest" ]; then rm -rf "$dest"; echo "removed  $dest (symlink)"
    elif [ -f "$dest/SKILL.md" ] && grep -q '^name: pilot' "$dest/SKILL.md" 2>/dev/null; then rm -rf "$dest"; echo "removed  $dest"
    elif [ -e "$dest" ]; then echo "SKIP (exists, not a pilot install): $dest"
    else echo "absent   $dest"; fi
    return
  fi
  # refuse to clobber a real dir that isn't ours (symlink or a dir carrying our marker are safe to replace)
  if [ -e "$dest" ] && [ ! -L "$dest" ] && ! grep -q '^name: pilot' "$dest/SKILL.md" 2>/dev/null; then
    echo "SKIP (exists, not a pilot install): $dest" >&2; return
  fi
  rm -rf "$dest"
  if [ "$mode" = "link" ]; then
    ln -s "$SRC" "$dest"; echo "linked   $dest -> $SRC"
  else
    cp -R "$SRC" "$dest"; echo "copied   $dest"
  fi
}

[ "$do_claude" = 1 ] && place "$HOME/.claude/skills"
[ "$do_codex"  = 1 ] && place "$HOME/.codex/skills"
if [ -n "$project" ]; then
  place "$project/.claude/skills"   # Claude Code project-level
  place "$project/.agents/skills"   # Codex project-level
fi

echo
if [ "$uninstall" = 0 ]; then
  echo "Done. Invoke with:  pilot status | plan | run"
  echo "(Claude Code: /pilot ...   Codex: \$pilot ...)"
fi
