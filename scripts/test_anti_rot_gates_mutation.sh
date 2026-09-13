#!/usr/bin/env bash
# 两道防腐闸负测的「有牙齿」证明（变异测试）。
#
# 为什么需要这一层：负测全 ok 有两种可能 —— (1) 闸真的会响；(2) 负测的断言根本
# 没走到被测判据（本工程出过：断言被前置门挡掉却报 PASS）。变异测试把闸的核心
# 判据一条条打瘸，**负测必须因此失败**，且必须是**对应那条**断言失败。
#
# ★退出码陷阱★ 光看「变异后测试非零退出」不够：把脚本改出语法错，测试也非零
# 退出，看着像「抓到了」，实际是崩了。所以每条变异都额外要求：
#   - 输出里出现 `FAILED`（测试自己的汇总行，证明是断言失败不是解释器崩溃）
#   - 输出里出现**预期那条断言的关键字**
#   - 输出里**不含 Traceback**
#
# 跑法: bash scripts/test_anti_rot_gates_mutation.sh   （退出码 0 = 变异全被抓）
set -u

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fails=0

# mutate <测试脚本> <被变异文件> <sed表达式> <预期断言关键字> <说明>
mutate() {
  local test_script="$1" victim="$2" sedexpr="$3" keyword="$4" desc="$5"
  local tmp; tmp="$(mktemp -d)"
  cp -r "$SRC" "$tmp/scripts"
  sed -i "$sedexpr" "$tmp/scripts/$victim" || { echo "  FAIL sed 没应用: $desc"; fails=$((fails+1)); return; }

  # 变异必须真的改到了文件，否则这条变异测试等于没做
  if diff -q "$SRC/$victim" "$tmp/scripts/$victim" >/dev/null; then
    echo "  FAIL 变异没改动文件（sed 没匹配上）: $desc"
    fails=$((fails+1)); rm -rf "$tmp"; return
  fi

  local out rc
  out="$(cd "$tmp" && python3 "$tmp/scripts/$test_script" 2>&1)"; rc=$?

  if [ $rc -eq 0 ]; then
    echo "  FAIL 变异后负测仍然全过（负测没牙齿）: $desc"
    fails=$((fails+1))
  elif echo "$out" | grep -q 'Traceback'; then
    echo "  FAIL 变异让脚本崩了，不是断言失败（无效变异）: $desc"
    fails=$((fails+1))
  elif ! echo "$out" | grep -q 'FAILED'; then
    echo "  FAIL 非零退出但没有 FAILED 汇总行（可疑）: $desc"
    fails=$((fails+1))
  elif ! echo "$out" | grep -q -- "$keyword"; then
    echo "  FAIL 失败的不是预期那条断言（期望含 '$keyword'）: $desc"
    echo "$out" | grep -- '- ' | head -5
    fails=$((fails+1))
  else
    echo "  ok   变异被抓: $desc"
  fi
  rm -rf "$tmp"
}

echo "== 变异 equality_dup_lint.py 的核心判据 =="
mutate test_equality_dup_lint.py equality_dup_lint.py \
  's/if len(set(live)) != 1:/if False:/' \
  'DIVERGED' \
  '关掉 DIVERGED（分叉检测）'

mutate test_equality_dup_lint.py equality_dup_lint.py \
  's/^        if r is None:/        if False:/' \
  'UNDECLARED_DUPLICATE' \
  '关掉 UNDECLARED_DUPLICATE（未登记重复）'

mutate test_equality_dup_lint.py equality_dup_lint.py \
  's/if live\[0\] != r\[.pinned_sha256.\]\[0\]:/if False:/' \
  'HASH_STALE' \
  '关掉 HASH_STALE（同步改动的留痕）'

mutate test_equality_dup_lint.py equality_dup_lint.py \
  's/raise RuntimeError(/return rows; _unused=(/' \
  'rc=2' \
  '把登记表解析改成 fail-open（读不懂就放行）'

echo
echo "== 变异 bridge_report_lint.py 的核心判据 =="
mutate test_bridge_report_lint.py bridge_report_lint.py \
  's/if not any(l.strip() for l in content):/if False:/' \
  'EMPTY_CODE_BLOCK' \
  '关掉 EMPTY_CODE_BLOCK（0147/0148 事故环节一）'

mutate test_bridge_report_lint.py bridge_report_lint.py \
  's/elif declared and declared not in where:/elif False:/' \
  'COMMIT_WRONG_REPO' \
  '关掉 COMMIT_WRONG_REPO（0147/0148 事故环节二）'

mutate test_bridge_report_lint.py bridge_report_lint.py \
  's/elif int(nums\[-1\]) != expect:/elif False:/' \
  'COUNT_MISMATCH' \
  '关掉 COUNT_MISMATCH（计数复算）'

mutate test_bridge_report_lint.py bridge_report_lint.py \
  's/if pr.returncode != 0:/if False:/' \
  'COUNT_CMD_FAILED' \
  '关掉「命令非零退出不得当事实」'

mutate test_bridge_report_lint.py bridge_report_lint.py \
  's/if actual != claimed:/if False:/' \
  'SHA256_MISMATCH' \
  '关掉 SHA256_MISMATCH'

echo
if [ $fails -ne 0 ]; then
  echo "变异测试 FAILED: $fails 条变异没被负测抓到"
  exit 1
fi
echo "全部变异都被负测抓到（负测有牙齿）"
exit 0
