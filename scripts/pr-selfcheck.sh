#!/usr/bin/env bash
# pr-selfcheck.sh —— 提 PR 前的机械自检(只做 100% 可判定的两类)
#
# 由 PR-Daemon 一千余轮 review 的记录反推:错误按类聚合后,只有极少数是「机械可判」的
# —— 既不需要读懂业务,也不存在解释空间,判错了一定是脚本的 bug 而不是口味问题。
# 本脚本**只**收这两类。其余高频类(测试不承重 35.1%、常量半扫 5.4%、set -e 吞退出码
# 6.5%)都需要语义判断,放进来必然误报,第一天就会被 --no-verify / [skip ci] 绕过去,
# 那比没有更糟 —— 一个被普遍绕过的闸门会让人以为已经检查过了。
#
#   cite   引用指向不存在的文件 / 解析不到的 commit
#   state  jq > tmp; mv 缺非空守卫(jq 失败时用空文件覆盖状态)
#
# 用法:
#   bash scripts/pr-selfcheck.sh                   # 自动取 base(origin/main 等)
#   bash scripts/pr-selfcheck.sh --base <sha>
#   bash scripts/pr-selfcheck.sh cite              # 只跑某一项
#   SELFCHECK_SKIP=state bash scripts/pr-selfcheck.sh
#
# 退出码: 0 = 无 FAIL(可能有 WARN); 1 = 有 FAIL
#
# ⚠️ 注意本脚本自己**不能**用 `set -u`:下面的 `while IFS='|' read -r kind ...` 在读到
#    EOF 时 kind 未绑定,-u 会让脚本在正常结束时报错退出 —— 这正是 state 那一类要抓的
#    同一种毛病。这里显式用 ${kind:-} 守卫代替。
set -o pipefail

BASE="${SELFCHECK_BASE:-}"
ONLY=""
while [ $# -gt 0 ]; do
  case "$1" in
    --base) BASE="$2"; shift 2 ;;
    -h|--help) sed -n '2,25p' "$0"; exit 0 ;;
    *) ONLY="$ONLY $1"; shift ;;
  esac
done

FAIL=0; WARN=0
red() { printf '\033[31mFAIL\033[0m  %s\n' "$1"; FAIL=$((FAIL+1)); }
yel() { printf '\033[33mWARN\033[0m  %s\n' "$1"; WARN=$((WARN+1)); }
grn() { printf '\033[32m ok \033[0m  %s\n' "$1"; }
hdr() { printf '\n\033[1m== %s\033[0m\n' "$1"; }
run() {
  case " $SELFCHECK_SKIP " in *" $1 "*) return 1 ;; esac
  [ -z "${ONLY# }" ] && return 0
  case " $ONLY " in *" $1 "*) return 0 ;; *) return 1 ;; esac
}

if [ -z "$BASE" ]; then
  for b in origin/main origin/master main master; do
    git rev-parse --verify -q "$b" >/dev/null 2>&1 && { BASE="$(git merge-base HEAD "$b" 2>/dev/null)"; break; }
  done
fi
[ -n "$BASE" ] || BASE="$(git rev-parse HEAD~1 2>/dev/null || echo HEAD)"
CHANGED="$(git diff --name-only "$BASE"..HEAD 2>/dev/null | grep -v '^$' || true)"
[ -n "$CHANGED" ] || { echo "(相对 $BASE 无改动)"; exit 0; }

TMP="$(mktemp -t selfcheck.XXXXXX)"
trap 'rm -f "$TMP"' EXIT

# ── cite:引用必须能解析 ───────────────────────────────────────────────
# 两个方向都要扫,少任何一边都会漏掉整整一类:
#   ① 引用侧:本次**新增的行**引了不存在的路径/commit
#   ② 目标侧:本次**删除/改名**的文件仍被仓内 md 引用
# 只做 ① 的话,「存量文档 + 本次删掉被引文件」这条最典型的真发现会漏(实测漏过);
# 只做 ② 的话,新写的文档里编造的路径会漏。
# 都不扫全仓存量 —— 否则每个 PR 都把仓库历史债务重报一遍(实测 26 报 25 误),
# 而与本次改动无关的报警正是让人开始无脑绕过闸门的原因。
if run cite; then
  hdr "cite 引用解析(改动的 md / 本次删除的文件)"
  hits=0
  for f in $CHANGED; do
    case "$f" in *.md|*.MD) ;; *) continue ;; esac
    [ -f "$f" ] || continue
    git diff "$BASE"..HEAD -- "$f" 2>/dev/null | grep '^+' | grep -v '^+++' \
      | grep -oE '`[A-Za-z0-9_./-]+\.(md|sh|ts|js|mjs|sol|py|rs|json|toml|yml|yaml)`' 2>/dev/null \
      | tr -d '`' | sort -u | while read -r p; do
        [ -e "$p" ] && continue
        bn="$(basename "$p")"
        # 散文里常只写文件名不写完整路径,仓内存在同名文件就不算悬空(否则大量误报)
        git ls-files "*/$bn" "$bn" 2>/dev/null | grep -q . && continue
        command -v "$bn" >/dev/null 2>&1 && continue
        echo "CITE_MISS|$f|$p"
      done
    # 短 SHA 要求至少含一个 a-f 字母 —— 否则 chainId 11155111 这类纯数字被当成 commit(实测误报)
    git diff "$BASE"..HEAD -- "$f" 2>/dev/null | grep '^+' | grep -v '^+++' \
      | grep -oE '\b[0-9a-f]{8}\b' 2>/dev/null | grep -E '[a-f]' | sort -u | while read -r s; do
        git cat-file -t "$s" >/dev/null 2>&1 || echo "SHA_MISS|$f|$s"
      done
  done > "$TMP" 2>/dev/null || true

  git diff --name-status "$BASE"..HEAD 2>/dev/null | awk '$1 ~ /^[DR]/ {print $2}' \
    | while read -r gone; do
        [ -n "$gone" ] || continue
        [ -e "$gone" ] && continue          # 改名但旧路径仍在 → 不算
        gb="$(basename "$gone")"
        git grep -l -F -- "$gb" -- '*.md' '*.MD' 2>/dev/null | while read -r src; do
          case " $CHANGED " in *" $src "*) ;; *) echo "CITE_GONE|$src|$gone" ;; esac
        done
      done >> "$TMP" 2>/dev/null || true

  while IFS='|' read -r kind cf tgt || [ -n "${kind:-}" ]; do
    [ -n "${kind:-}" ] || continue
    hits=$((hits+1))
    case "$kind" in
      CITE_MISS) red "$cf 引用了不存在的 $tgt(仓内 / PATH 均未找到)" ;;
      CITE_GONE) red "$cf 仍引用 $tgt —— 本次改动把它删除/改名了,引用侧没跟着改" ;;
      SHA_MISS)  yel "$cf 提到 commit $tgt,本仓解析不到 —— 若是外仓 SHA 请写明仓库并确认 public" ;;
    esac
  done < "$TMP" 2>/dev/null
  [ "$hits" -gt 0 ] || grn "引用的路径 / commit 都能解析,删掉的文件也没人还引着"
fi

# ── state:jq > tmp; mv 缺非空守卫 ─────────────────────────────────────
# `jq … "$F" > "$F.tmp"; mv "$F.tmp" "$F"` 里,jq 失败时 shell 已经把 .tmp 建成空文件,
# mv 照样成功 —— 状态文件被清空。这不是理论:一次「计数器写失败 → fail-open → 永不
# 拉黑坏版本」的实际链路,根因就是这个写法,而且它在同一个文件里被复制了好几份。
# 判据只有一条:mv 之前有没有 `&&` 串联或 `-s` 非空检查。零解释空间。
if run state; then
  hdr "state 状态写入原子性(jq > tmp; mv 缺非空守卫)"
  hits=0
  for f in $CHANGED; do
    case "$f" in *.sh|*.bash) ;; *) continue ;; esac
    [ -f "$f" ] || continue
    grep -nE 'jq[^|]*>[[:space:]]*"?\$?\{?[A-Za-z_/.][^;&]*\.tmp' "$f" 2>/dev/null \
      | while IFS=: read -r ln _; do
          # 看该行及其后两行:出现 && 串联 或 [ -s … ] 即视为有守卫
          sed -n "${ln},$((ln+2))p" "$f" 2>/dev/null | grep -qE '&&|\[[[:space:]]+-s[[:space:]]' && continue
          sed -n "${ln},$((ln+2))p" "$f" 2>/dev/null | grep -q 'mv' || continue
          echo "STATE|$f|$ln"
        done
  done > "$TMP" 2>/dev/null || true
  while IFS='|' read -r kind sf ln || [ -n "${kind:-}" ]; do
    [ -n "${kind:-}" ] || continue
    hits=$((hits+1))
    red "$sf:$ln 有 \`jq … > *.tmp\` 后直接 mv,缺 && 串联或 -s 非空守卫 —— jq 失败会把空文件覆盖上去"
  done < "$TMP" 2>/dev/null
  [ "$hits" -gt 0 ] || grn "改动的 shell 里没有无守卫的 jq→tmp→mv"
fi

printf '\n== 汇总 ==  FAIL=%s WARN=%s  (base=%s)\n' "$FAIL" "$WARN" "$(echo "$BASE" | cut -c1-12)"
[ "$FAIL" -eq 0 ]
