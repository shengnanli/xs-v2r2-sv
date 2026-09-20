#!/bin/bash
# =============================================================================
# parse_sim_errors.sh —— 从一份 UT sim.log 里取出**最终**的 errors 数。
#
# ★为什么要单独一个文件★
# 2026-09-20 实测：mutants.sh 原来用
#       grep -oP 'errors=\K\d+' sim.log | head -1
# 取判据。而 tb 的日志里**第一个** `errors=` 是定向段打的
#       DIRECTED mbmc_sfence errors=0
# 它几乎永远是 0。于是**除了被定向段抓到的那一个变异体以外，每一个变异体都被读成
# errors=0，报成"★没抓出来"**。实测对照（C2 变异体，60000 拍）：
#       日志第 5 行 : DIRECTED mbmc_sfence errors=0        <- head -1 读的是它
#       日志第 86 行: checks=60000 errors=56350 (含 directed=0)  <- 真判据
# 这是一个 **fail-open** 的判据 bug：它只会把"抓住了"误报成"没抓住"的反面 ——
# 更糟的是它让判别力报告整体偏悲观**并且不可信**，两个方向都没法用。
#
# 所以判据锚定到最终那一行的形状 `^checks=<n> errors=<n>`，并且：
#   · 找不到该行 ⇒ 退出码 2（**不是**返回 0）—— 没跑完的日志绝不能读成"0 错"；
#   · 多行匹配 ⇒ 取最后一行（一份日志只该有一份总结）。
#
# 用法: parse_sim_errors.sh <sim.log>      stdout = errors 数, rc=0
#       parse_sim_errors.sh --selftest     判据自身的双向负测
# =============================================================================
set -u

parse() {
  local f=$1 line
  [ -f "$f" ] || { echo "PARSE_ERROR: 日志不存在: $f" >&2; return 2; }
  line=$(grep -E '^checks=[0-9]+ errors=[0-9]+' "$f" | tail -1)
  [ -n "$line" ] || { echo "PARSE_ERROR: 日志里没有 '^checks=<n> errors=<n>' 总结行（仿真没跑完？）: $f" >&2; return 2; }
  echo "$line" | sed -E 's/^checks=[0-9]+ errors=([0-9]+).*/\1/'
}

# ---------------------------------------------------------------------------
# ★闸的负测必须是双向的★（CONVENTIONS）：既要证明它**会**看见真错误，
# 也要证明它**不会**把没错的读成有错，外加"读不出来时必须报错而不是返 0"。
# ---------------------------------------------------------------------------
selftest() {
  local t rc out fails=0
  t=$(mktemp -d) || return 2

  # 方向一：真错误被读出来。★这份样本刻意复刻踩过的坑★ ——
  #         第一行是 DIRECTED errors=0，老判据(head -1)会读成 0。
  printf 'DIRECTED mbmc_sfence errors=0\nvec 7 io_r_resp_0_bits_hit g=1 i=0\nchecks=60000 errors=56350 (含 directed=0)\nTEST FAILED\n' > "$t/a.log"
  out=$(parse "$t/a.log"); rc=$?
  if [ "$rc" = 0 ] && [ "$out" = 56350 ]; then echo "  [ok] 方向一 真错误读出 56350（老判据 head -1 会读成 0）"
  else echo "  [FAIL] 方向一：期望 56350 得到 '$out' rc=$rc"; fails=$((fails+1)); fi
  # 同一份样本上把老判据也跑一遍，把"它确实会错"钉成可复跑的事实
  old=$(grep -oP 'errors=\K\d+' "$t/a.log" | head -1)
  if [ "$old" = 0 ]; then echo "  [ok] 方向一 反证：老判据(head -1)在同一份日志上确实读出 0"
  else echo "  [FAIL] 方向一反证：老判据本应读出 0，得到 '$old'"; fails=$((fails+1)); fi

  # 方向二：没有错误时不许误报
  printf 'DIRECTED mbmc_sfence errors=0\nchecks=60000 errors=0 (含 directed=0)\nTEST PASSED\n' > "$t/b.log"
  out=$(parse "$t/b.log"); rc=$?
  if [ "$rc" = 0 ] && [ "$out" = 0 ]; then echo "  [ok] 方向二 无错误读出 0，不误报"
  else echo "  [FAIL] 方向二：期望 0 得到 '$out' rc=$rc"; fails=$((fails+1)); fi

  # 方向三：日志没跑完（只有定向行）必须**报错**，不许静默返 0
  printf 'DIRECTED mbmc_sfence errors=0\n' > "$t/c.log"
  out=$(parse "$t/c.log" 2>/dev/null); rc=$?
  if [ "$rc" = 2 ]; then echo "  [ok] 方向三 日志不完整 ⇒ rc=2（不静默返 0）"
  else echo "  [FAIL] 方向三：期望 rc=2 得到 rc=$rc out='$out'"; fails=$((fails+1)); fi

  # 方向四：文件不存在也必须报错
  out=$(parse "$t/nope.log" 2>/dev/null); rc=$?
  if [ "$rc" = 2 ]; then echo "  [ok] 方向四 日志不存在 ⇒ rc=2"
  else echo "  [FAIL] 方向四：期望 rc=2 得到 rc=$rc"; fails=$((fails+1)); fi

  rm -rf "$t"
  [ $fails -eq 0 ] && echo "parse_sim_errors 自测全过（4 项）" || echo "parse_sim_errors 自测失败 $fails 项"
  return $fails
}

case "${1:-}" in
  --selftest) selftest ;;
  "") echo "用法: $0 <sim.log> | --selftest" >&2; exit 2 ;;
  *) parse "$1" ;;
esac
