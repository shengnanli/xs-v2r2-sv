#!/usr/bin/env bash
# 提交态证据自包含校验(验收二审): 从指定 commit 做 clean archive, 逐会话验证
# MANIFEST 每文件 size/sha256 与 COMPLETE(=MANIFEST 的 sha256)。工作树内容不参与。
# 用法: step3b_archive_check.sh <commit>
set -u
SIGNOFF="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
COMMIT=${1:?用法: step3b_archive_check.sh <commit>}
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
git -C "$SIGNOFF" archive "$COMMIT" scripts/sidecar/step3b-evidence | tar -x -C "$TMP" || {
  echo "ARCHIVE_CHECK: FAIL(archive 失败)"; exit 2; }
E="$TMP/scripts/sidecar/step3b-evidence"
total_bad=0; sessions=0
for d in "$E"/*/; do
  s=$(basename "$d"); sessions=$((sessions+1))
  if [ ! -f "$d/MANIFEST.tsv" ] || [ ! -f "$d/COMPLETE" ]; then
    echo "  $s: MISSING MANIFEST/COMPLETE"; total_bad=$((total_bad+1)); continue
  fi
  bad=0; missing=0
  while IFS=$'\t' read -r f sz h; do
    [ "$f" = "COMPLETE" ] && continue
    if [ ! -f "$d/$f" ]; then echo "  $s: MISSING $f"; missing=$((missing+1)); continue; fi
    a=$(stat -c%s "$d/$f"); b=$(sha256sum "$d/$f" | cut -d' ' -f1)
    [ "$a" = "$sz" ] && [ "$b" = "$h" ] || { echo "  $s: BAD $f"; bad=$((bad+1)); }
  done < "$d/MANIFEST.tsv"
  c_ok=$([ "$(sha256sum "$d/MANIFEST.tsv" | cut -d' ' -f1)" = "$(cat "$d/COMPLETE")" ] && echo OK || echo BAD)
  echo "  $s: manifest不符=$bad 缺失=$missing COMPLETE=$c_ok"
  [ $bad -eq 0 ] && [ $missing -eq 0 ] && [ "$c_ok" = "OK" ] || total_bad=$((total_bad+1))
done
echo "ARCHIVE_CHECK($COMMIT): sessions=$sessions bad=$total_bad"
[ $total_bad -eq 0 ] && [ $sessions -gt 0 ]
