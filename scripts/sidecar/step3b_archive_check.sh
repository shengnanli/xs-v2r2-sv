#!/usr/bin/env bash
# 提交态证据自包含校验(验收三审强化版): 从 commit 做 clean archive, 校验:
#   ① session 集合与固定六会话**精确相等**(多/少均 FAIL)
#   ② MANIFEST 路径合法(禁绝对路径/../重复), 逐文件 size/sha256
#   ③ 目录内**无 MANIFEST 之外的多余文件**(extra 拒), 无 symlink/非常规文件
#   ④ COMPLETE == sha256(MANIFEST.tsv)
# 用法: step3b_archive_check.sh <commit>
set -u
SIGNOFF="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
COMMIT=${1:?用法: step3b_archive_check.sh <commit>}
ROOT="scripts/sidecar/step3b-evidence-r3"
EXPECT_SESSIONS="bku_strict bku_unread_true_probe imsic_strict intercept_direct intercept_dynamic intercept_nested"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
git -C "$SIGNOFF" archive "$COMMIT" "$ROOT" | tar -x -C "$TMP" || {
  echo "ARCHIVE_CHECK: FAIL(archive 失败)"; exit 2; }
E="$TMP/$ROOT"
total_bad=0

# ① 会话集合精确相等
got=$(cd "$E" && LC_ALL=C ls -d */ 2>/dev/null | sed 's|/$||' | LC_ALL=C sort | tr '\n' ' ' | sed 's/ $//')
want=$(echo "$EXPECT_SESSIONS" | tr ' ' '\n' | LC_ALL=C sort | tr '\n' ' ' | sed 's/ $//')
if [ "$got" != "$want" ]; then
  echo "  SESSION_SET MISMATCH: got=[$got] want=[$want]"; total_bad=$((total_bad+1))
fi

# symlink/非常规文件全树拒
nlink=$(find "$E" ! -type f ! -type d | wc -l)
[ "$nlink" != "0" ] && { echo "  NON_REGULAR entries=$nlink"; total_bad=$((total_bad+1)); }

for s in $EXPECT_SESSIONS; do
  d="$E/$s"
  if [ ! -f "$d/MANIFEST.tsv" ] || [ ! -f "$d/COMPLETE" ]; then
    echo "  $s: MISSING MANIFEST/COMPLETE"; total_bad=$((total_bad+1)); continue
  fi
  bad=0; missing=0; extra=0; dup=0; badpath=0
  declare -A listed=()
  while IFS=$'\t' read -r f sz h; do
    case "$f" in
      /*|*..*|"") echo "  $s: BADPATH $f"; badpath=$((badpath+1)); continue ;;
    esac
    [ -n "${listed[$f]:-}" ] && { echo "  $s: DUP $f"; dup=$((dup+1)); continue; }
    listed[$f]=1
    if [ ! -f "$d/$f" ]; then echo "  $s: MISSING $f"; missing=$((missing+1)); continue; fi
    a=$(stat -c%s "$d/$f"); b=$(sha256sum "$d/$f" | cut -d' ' -f1)
    [ "$a" = "$sz" ] && [ "$b" = "$h" ] || { echo "  $s: BAD $f"; bad=$((bad+1)); }
  done < "$d/MANIFEST.tsv"
  # extra: 目录内每个文件必须在 MANIFEST(或为 MANIFEST/COMPLETE 本身)
  while read -r f; do
    [ "$f" = "MANIFEST.tsv" ] || [ "$f" = "COMPLETE" ] && continue
    [ -n "${listed[$f]:-}" ] || { echo "  $s: EXTRA $f"; extra=$((extra+1)); }
  done < <(cd "$d" && find . -type f | sed 's|^\./||')
  c_ok=$([ "$(sha256sum "$d/MANIFEST.tsv" | cut -d' ' -f1)" = "$(cat "$d/COMPLETE")" ] && echo OK || echo BAD)
  echo "  $s: 不符=$bad 缺失=$missing 多余=$extra 重复=$dup 坏路径=$badpath COMPLETE=$c_ok"
  [ $bad -eq 0 ] && [ $missing -eq 0 ] && [ $extra -eq 0 ] && [ $dup -eq 0 ] && \
    [ $badpath -eq 0 ] && [ "$c_ok" = "OK" ] || total_bad=$((total_bad+1))
  unset listed
done
echo "ARCHIVE_CHECK($COMMIT): bad=$total_bad"
[ $total_bad -eq 0 ]
