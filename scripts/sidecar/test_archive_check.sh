#!/usr/bin/env bash
# archive verifier 负向测试(五审固化): 曾 rc=0 的三类伪造必须 FAIL。
# 需要一份真实证据基线(step3b-evidence-r3, 提交态)+ 其 expected_impl_commit。
set -u
SC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SIGNOFF="$(cd "$SC/../.." && pwd)"
CK="$SC/step3b_archive_check.sh"
SRC="$SC/step3b-evidence-r3"
pass=0; fail=0
T() { local name=$1 want=$2 rc=$3
  if [ "$rc" = "$want" ]; then echo "PASS  $name"; pass=$((pass+1))
  else echo "FAIL  $name(rc=$rc want=$want)"; fail=$((fail+1)); fi }
recompute() { # 重算某会话 MANIFEST/COMPLETE(伪造者视角)
  local d=$1
  ( cd "$d" && LC_ALL=C find . -type f ! -name MANIFEST.tsv ! -name COMPLETE | LC_ALL=C sort | \
    sed 's|^\./||' | while read -r f; do
      printf '%s\t%s\t%s\n' "$f" "$(stat -c%s "$f")" "$(sha256sum "$f"|cut -d' ' -f1)"
    done > MANIFEST.tsv; sha256sum MANIFEST.tsv | cut -d' ' -f1 > COMPLETE )
}

# 对抗1: 六个固定目录各只有空 MANIFEST + 匹配 COMPLETE
D1=$(mktemp -d)
for s in bku_strict bku_unread_true_probe imsic_strict intercept_direct intercept_dynamic intercept_nested; do
  mkdir -p "$D1/$s"; : > "$D1/$s/MANIFEST.tsv"; sha256sum "$D1/$s/MANIFEST.tsv"|cut -d' ' -f1 > "$D1/$s/COMPLETE"
done
bash "$CK" --tree "$D1" deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef >/dev/null 2>&1
T empty_manifest_six_dirs 1 $?
rm -rf "$D1"

if [ ! -d "$SRC/bku_strict" ]; then echo "SKIP(无 r3 证据)"; echo "$pass/$((pass+fail)) passed"; exit 0; fi
REAL_IMPL=$(awk -F'\t' '$1=="impl_commit"{print $2}' "$SRC/imsic_strict/TOOLS.tsv" | head -1)

# 对抗2: 篡改 TOOLS(dirty_post=1)+RESULT(CLEAN_GATE_FAIL), 重算清单
D2=$(mktemp -d); cp -r "$SRC"/* "$D2"/ 2>/dev/null; rm -f "$D2"/*.txt "$D2"/*.MANIFEST.tsv 2>/dev/null
sed -i 's/^worktree_tracked_dirty_post\t0/worktree_tracked_dirty_post\t1/' "$D2/bku_strict/TOOLS.tsv"
echo "CLEAN_GATE_FAIL x" >> "$D2/bku_strict/RESULT.txt"
recompute "$D2/bku_strict"
bash "$CK" --tree "$D2" "$REAL_IMPL" >/dev/null 2>&1; T tampered_tools_selfconsistent 1 $?
rm -rf "$D2"

# 对抗3(五审新): native JSON 改 {}, fm_shell.rc=999, RESULT 伪造, 重算 MANIFEST/COMPLETE
D3=$(mktemp -d); cp -r "$SRC"/* "$D3"/ 2>/dev/null; rm -f "$D3"/*.txt "$D3"/*.MANIFEST.tsv 2>/dev/null
for s in bku_strict bku_unread_true_probe imsic_strict; do
  echo "{}" > "$D3/$s/native_facts.json"
  echo "999" > "$D3/$s/fm_shell.rc"
  echo "SESSION_RESULT $s: SUCCEEDED (forged)" > "$D3/$s/RESULT.txt"
  recompute "$D3/$s"
done
bash "$CK" --tree "$D3" "$REAL_IMPL" >/dev/null 2>&1; T forged_native_json_and_rc 1 $?
rm -rf "$D3"

# 对抗4(五审新): reject 会话塞入 native_facts(应被拒: reject 须 facts 缺席)
D4=$(mktemp -d); cp -r "$SRC"/* "$D4"/ 2>/dev/null; rm -f "$D4"/*.txt "$D4"/*.MANIFEST.tsv 2>/dev/null
echo '{"x":1}' > "$D4/intercept_direct/native_facts.json"; recompute "$D4/intercept_direct"
bash "$CK" --tree "$D4" "$REAL_IMPL" >/dev/null 2>&1; T reject_with_native_facts 1 $?
rm -rf "$D4"

# ===== 六审六洞负测 =====
# 洞1: RESULT 声称 SUCCEEDED, native 真实 PARTIAL(仅改 RESULT 行, 其余不动)
D5=$(mktemp -d); cp -r "$SRC"/* "$D5"/ 2>/dev/null; rm -f "$D5"/*.txt "$D5"/*.MANIFEST.tsv 2>/dev/null
sed -i 's/^SESSION_RESULT bku_strict: PARTIAL.*/SESSION_RESULT bku_strict: SUCCEEDED\tclean/' "$D5/bku_strict/RESULT.txt"
recompute "$D5/bku_strict"
bash "$CK" --tree "$D5" "$REAL_IMPL" >/dev/null 2>&1; T hole1_result_claims_success 1 $?; rm -rf "$D5"

# 洞2: reject fm_shell.rc 3→999
D6=$(mktemp -d); cp -r "$SRC"/* "$D6"/ 2>/dev/null; rm -f "$D6"/*.txt "$D6"/*.MANIFEST.tsv 2>/dev/null
echo 999 > "$D6/intercept_direct/fm_shell.rc"; recompute "$D6/intercept_direct"
bash "$CK" --tree "$D6" "$REAL_IMPL" >/dev/null 2>&1; T hole2_reject_rc_forged 1 $?; rm -rf "$D6"

# 洞3: 预期 ERROR 会话注入重复 JSON 键(native_facts)→ 应因 JSON_PARSE_FAIL 拒(非误过)
D7=$(mktemp -d); cp -r "$SRC"/* "$D7"/ 2>/dev/null; rm -f "$D7"/*.txt "$D7"/*.MANIFEST.tsv 2>/dev/null
printf '{"schema":"x","schema":"y"}' > "$D7/bku_unread_true_probe/native_facts.json"
recompute "$D7/bku_unread_true_probe"
bash "$CK" --tree "$D7" "$REAL_IMPL" >/dev/null 2>&1; T hole3_dup_json_keys 1 $?; rm -rf "$D7"

# 洞4: 五条 infra 全重复同一合法文件
D8=$(mktemp -d); cp -r "$SRC"/* "$D8"/ 2>/dev/null; rm -f "$D8"/*.txt "$D8"/*.MANIFEST.tsv 2>/dev/null
onef=$(awk -F'\t' '$1=="infra"{print; exit}' "$D8/bku_strict/TOOLS.tsv")
grep -v '^infra\t' "$D8/bku_strict/TOOLS.tsv" > "$D8/bku_strict/TOOLS.tmp"
for i in 1 2 3 4 5; do echo "$onef" >> "$D8/bku_strict/TOOLS.tmp"; done
mv "$D8/bku_strict/TOOLS.tmp" "$D8/bku_strict/TOOLS.tsv"; recompute "$D8/bku_strict"
bash "$CK" --tree "$D8" "$REAL_IMPL" >/dev/null 2>&1; T hole4_infra_all_same 1 $?; rm -rf "$D8"

# 洞6: 篡改 sourced_*(script closure 快照)→ 应 CLOSURE_SNAP_TAMPERED
D9=$(mktemp -d); cp -r "$SRC"/* "$D9"/ 2>/dev/null; rm -f "$D9"/*.txt "$D9"/*.MANIFEST.tsv 2>/dev/null
snapf=$(ls "$D9/bku_strict"/sourced_000_* | head -1); echo "# tamper" >> "$snapf"
recompute "$D9/bku_strict"
bash "$CK" --tree "$D9" "$REAL_IMPL" >/dev/null 2>&1; T hole6_snapshot_tampered 1 $?; rm -rf "$D9"

# 正样本: 真实证据必须 PASS(rc=0)
bash "$CK" --tree "$SRC" "$REAL_IMPL" >/dev/null 2>&1; T real_evidence_passes 0 $?

echo "$pass/$((pass+fail)) passed"
[ $fail -eq 0 ]
