#!/usr/bin/env bash
# 提交态证据校验(验收四审语义版)。此前只证"清单自洽"被裁定可假绿(空 MANIFEST 六目录
# rc=0 / 篡改 TOOLS+RESULT 后重算清单 rc=0)。现校验**语义**:
#   ① 固定六会话集合精确相等; symlink/非常规/extra/坏路径/重复拒(同三审)
#   ② 按会话类型的**非空必需 pathset**(native 会话须有 facts/envelope/expectation;
#      intercept 会话须有刺激且 native_facts.json **必须缺席**)
#   ③ TOOLS 严格解析: worktree_head_pre/post == impl_commit == <expected_impl_commit>,
#      tracked_dirty 前后=0, main_tracked_dirty=0, infra hash 行齐且 64-hex
#   ④ RESULT 拒 CLEAN_GATE_FAIL; RUNNER_RC 回执 == 会话类型期望 rc
# 用法: step3b_archive_check.sh <commit> <expected_impl_commit>
#       step3b_archive_check.sh --tree <dir> <expected_impl_commit>   (负向测试用)
set -u
SIGNOFF="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ROOT="scripts/sidecar/step3b-evidence-r3"
declare -A EXPECT_RC=([bku_strict]=1 [bku_unread_true_probe]=1 [imsic_strict]=1
                      [intercept_direct]=5 [intercept_dynamic]=5 [intercept_nested]=5)
NATIVE_SESSIONS="bku_strict bku_unread_true_probe imsic_strict"
REJECT_SESSIONS="intercept_direct intercept_dynamic intercept_nested"

if [ "$1" = "--tree" ]; then
  E=$2; EXPECT_IMPL=$3
else
  COMMIT=$1; EXPECT_IMPL=$2
  TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
  git -C "$SIGNOFF" archive "$COMMIT" "$ROOT" | tar -x -C "$TMP" || {
    echo "ARCHIVE_CHECK: FAIL(archive 失败)"; exit 2; }
  E="$TMP/$ROOT"
fi
total_bad=0

got=$(cd "$E" 2>/dev/null && LC_ALL=C ls -d */ 2>/dev/null | sed 's|/$||' | LC_ALL=C sort | tr '\n' ' ' | sed 's/ $//')
want=$(echo "$NATIVE_SESSIONS $REJECT_SESSIONS" | tr ' ' '\n' | LC_ALL=C sort | tr '\n' ' ' | sed 's/ $//')
[ "$got" != "$want" ] && { echo "  SESSION_SET MISMATCH: [$got] != [$want]"; total_bad=$((total_bad+1)); }
nlink=$(find "$E" ! -type f ! -type d 2>/dev/null | wc -l)
[ "$nlink" != "0" ] && { echo "  NON_REGULAR=$nlink"; total_bad=$((total_bad+1)); }

tools_val() { awk -F'\t' -v k="$1" '$1==k{print $2}' "$2" | head -1; }

check_session() {
  local s=$1 kind=$2 d="$E/$s" bad=0
  if [ ! -f "$d/MANIFEST.tsv" ] || [ ! -f "$d/COMPLETE" ]; then
    echo "  $s: MISSING MANIFEST/COMPLETE"; return 1; fi
  # 清单完整性(同三审: size/sha/extra/dup/坏路径)
  local m=0 x=0; declare -A listed=()
  while IFS=$'\t' read -r f sz h; do
    case "$f" in /*|*..*|"") echo "  $s: BADPATH $f"; bad=1; continue;; esac
    [ -n "${listed[$f]:-}" ] && { echo "  $s: DUP $f"; bad=1; continue; }
    listed[$f]=1
    [ -f "$d/$f" ] || { echo "  $s: MISSING $f"; bad=1; continue; }
    [ "$(stat -c%s "$d/$f")" = "$sz" ] && [ "$(sha256sum "$d/$f"|cut -d' ' -f1)" = "$h" ] \
      || { echo "  $s: BAD $f"; bad=1; }
  done < "$d/MANIFEST.tsv"
  while read -r f; do
    [ "$f" = "MANIFEST.tsv" ] || [ "$f" = "COMPLETE" ] && continue
    [ -n "${listed[$f]:-}" ] || { echo "  $s: EXTRA $f"; bad=1; }
  done < <(cd "$d" && find . -type f | sed 's|^\./||')
  [ "$(sha256sum "$d/MANIFEST.tsv"|cut -d' ' -f1)" = "$(cat "$d/COMPLETE")" ] \
    || { echo "  $s: COMPLETE BAD"; bad=1; }
  # ② 类型化必需 pathset(非空)
  local req="RESULT.txt TOOLS.tsv RUNNER_RC fm_shell.rc fm_log.txt make.out script_closure.list \
frozen/scripts/fm_eq.tcl frozen/scripts/fm_verdict.py frozen/scripts/sidecar/fm_native_emit.tcl"
  [ "$kind" = "native" ] && req="$req native_facts.json verdict.sidecar.json expectation.smoke.json probe_nc_unread.list"
  [ "$kind" = "reject" ] && req="$req stimulus_fm_pins_pre.tcl"
  for f in $req; do
    if [ ! -s "$d/$f" ]; then echo "  $s: REQUIRED_MISSING_OR_EMPTY $f"; bad=1; fi
  done
  local nsnap=$(ls "$d" 2>/dev/null | grep -c '^sourced_')
  [ "$nsnap" -ge 2 ] || { echo "  $s: SNAPSHOTS<2"; bad=1; }
  if [ "$kind" = "reject" ] && [ -f "$d/native_facts.json" ]; then
    echo "  $s: native_facts_MUST_BE_ABSENT"; bad=1; fi
  # ③ TOOLS 语义
  local t="$d/TOOLS.tsv"
  if [ -f "$t" ]; then
    local hp=$(tools_val worktree_head_pre "$t") hq=$(tools_val worktree_head_post "$t")
    local dp=$(tools_val worktree_tracked_dirty_pre "$t") dq=$(tools_val worktree_tracked_dirty_post "$t")
    local mc=$(tools_val impl_commit "$t") md=$(tools_val main_tracked_dirty "$t")
    [ "$hp" = "$EXPECT_IMPL" ] && [ "$hq" = "$EXPECT_IMPL" ] && [ "$mc" = "$EXPECT_IMPL" ] \
      || { echo "  $s: TOOLS_HEAD_MISMATCH($hp/$hq/$mc != $EXPECT_IMPL)"; bad=1; }
    [ "$dp" = "0" ] && [ "$dq" = "0" ] && [ "$md" = "0" ] \
      || { echo "  $s: TOOLS_DIRTY($dp/$dq/$md)"; bad=1; }
    local ninfra=$(awk -F'\t' '$1=="infra" && $3 ~ /^[0-9a-f]{64}$/' "$t" | wc -l)
    [ "$ninfra" -ge 5 ] || { echo "  $s: TOOLS_INFRA_HASHES=$ninfra<5"; bad=1; }
  fi
  # ④ RESULT/RUNNER_RC 语义
  grep -q "CLEAN_GATE_FAIL" "$d/RESULT.txt" 2>/dev/null && { echo "  $s: CLEAN_GATE_FAIL"; bad=1; }
  grep -q "^SESSION_RESULT $s:" "$d/RESULT.txt" 2>/dev/null || { echo "  $s: RESULT_LINE_MISSING"; bad=1; }
  [ "$kind" = "reject" ] && { grep -q "NO_NATIVE_FACTS" "$d/RESULT.txt" 2>/dev/null \
      || { echo "  $s: REJECT_RESULT_MISMATCH"; bad=1; }; }
  local rrc=$(cat "$d/RUNNER_RC" 2>/dev/null)
  [ "$rrc" = "${EXPECT_RC[$s]}" ] || { echo "  $s: RUNNER_RC=$rrc != ${EXPECT_RC[$s]}"; bad=1; }
  echo "  $s: $([ $bad -eq 0 ] && echo OK || echo FAIL)"
  return $bad
}

for s in $NATIVE_SESSIONS; do check_session "$s" native || total_bad=$((total_bad+1)); done
for s in $REJECT_SESSIONS; do check_session "$s" reject || total_bad=$((total_bad+1)); done
echo "ARCHIVE_CHECK: bad=$total_bad"
[ $total_bad -eq 0 ]
