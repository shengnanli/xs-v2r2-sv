#!/usr/bin/env bash
# archive checker 负向测试(验收四审固化): 两个曾实测 rc=0 的对抗必须 FAIL。
set -u
SC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CK="$SC/step3b_archive_check.sh"
IMPL=deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef
pass=0; fail=0
T() { local name=$1 want=$2 rc=$3
  if [ "$rc" = "$want" ]; then echo "PASS  $name"; pass=$((pass+1))
  else echo "FAIL  $name(rc=$rc want=$want)"; fail=$((fail+1)); fi }

# 对抗1: 六个固定目录各只有空 MANIFEST + 匹配 COMPLETE(曾 rc=0)→ 必须 FAIL
D1=$(mktemp -d)
for s in bku_strict bku_unread_true_probe imsic_strict intercept_direct intercept_dynamic intercept_nested; do
  mkdir -p "$D1/$s"; : > "$D1/$s/MANIFEST.tsv"
  sha256sum "$D1/$s/MANIFEST.tsv" | cut -d' ' -f1 > "$D1/$s/COMPLETE"
done
bash "$CK" --tree "$D1" "$IMPL" >/dev/null 2>&1; T empty_manifest_six_dirs 1 $?
rm -rf "$D1"

# 对抗2: 真实会话篡改 TOOLS(dirty_post=1)+RESULT(CLEAN_GATE_FAIL)后重算清单(曾 rc=0)→ FAIL
SRC="$SC/step3b-evidence-r3"
if [ -d "$SRC/bku_strict" ]; then
  D2=$(mktemp -d)
  cp -r "$SRC"/bku_strict "$SRC"/bku_unread_true_probe "$SRC"/imsic_strict \
        "$SRC"/intercept_direct "$SRC"/intercept_dynamic "$SRC"/intercept_nested "$D2"/ 2>/dev/null
  sed -i 's/^worktree_tracked_dirty_post\t0/worktree_tracked_dirty_post\t1/' "$D2/bku_strict/TOOLS.tsv"
  echo "CLEAN_GATE_FAIL head=x dirty=0/1" >> "$D2/bku_strict/RESULT.txt"
  ( cd "$D2/bku_strict" && LC_ALL=C find . -type f ! -name MANIFEST.tsv ! -name COMPLETE | \
    LC_ALL=C sort | sed 's|^\./||' | while read -r f; do
      printf '%s\t%s\t%s\n' "$f" "$(stat -c%s "$f")" "$(sha256sum "$f"|cut -d' ' -f1)"
    done > MANIFEST.tsv; sha256sum MANIFEST.tsv | cut -d' ' -f1 > COMPLETE )
  # 其余会话 TOOLS 用真实 impl commit; 篡改会话的 head 也保持真实 → 只有 dirty/CLEAN_GATE 露馅
  REAL_IMPL=$(awk -F'\t' '$1=="impl_commit"{print $2}' "$D2/imsic_strict/TOOLS.tsv" | head -1)
  bash "$CK" --tree "$D2" "$REAL_IMPL" >/dev/null 2>&1; T tampered_tools_selfconsistent_manifest 1 $?
  rm -rf "$D2"
else
  echo "SKIP tampered_tools(无 r3 证据)"
fi

echo "$pass/$((pass+fail)) passed"
[ $fail -eq 0 ]
