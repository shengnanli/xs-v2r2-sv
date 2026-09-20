#!/bin/bash
# NewDispatch UT 判别力自证 —— 往重写件里注入真 bug，UT 必须报出来。
# ★变异体不进库★：原文件先备份，每个变异体跑完立刻还原，脚本结束再用 sha256 复核。
#
# 为什么必须做：一个 UT 如果注入 bug 也不报错，它的 errors=0 没有意义。
# 本仓已踩过 7 种"看起来在验、实际没在验"的机制。
#
# 本 tb 的判据是 A/B/C 三条（见 tb.sv 头）：
#   MA-*  改一个**声明为 clean** 的位的真值 -> 必须触发判据 A（TEST FAILED）
# 复位域类变异（加 golden 没有的复位 / 改复位值）UT 按构造可能看不见，
# 由 scripts/nd_reset_domain_check.py 单独把闸 —— ★两道闸都看不见才算漏★。
#
# 第一版把整个 UT 目录复制出去跑，Makefile 里 `include ../../../scripts/ut_common.mk`
# 的相对路径当场断掉 —— 改成原地换文件 + 还原。
set -u
HERE=$(cd "$(dirname "$0")" && pwd)
REPO=$(cd "$HERE/../../.." && pwd)
SRC=$REPO/rtl/backend/NewDispatch.sv
BAK=$(mktemp /tmp/NewDispatch.orig.XXXXXX.sv)
NCYC=${NCYC:-2000}
cp "$SRC" "$BAK"
ORIG_SHA=$(sha256sum "$SRC" | cut -c1-64)
restore() { cp "$BAK" "$SRC"; }
trap 'restore; echo "(已还原原文件)"' EXIT INT TERM
echo "原文件 sha256=$ORIG_SHA，备份在 $BAK"

run_one() {
  local name=$1 patch=$2
  restore
  python3 - "$SRC" "$patch" <<'PY' || { echo "  [$name] 注入失败(锚点没找到)"; return 2; }
import sys
p, patch = sys.argv[1], sys.argv[2]
old, new = patch.split('||=>||')
t = open(p).read()
if old not in t:
    sys.exit("ANCHOR_NOT_FOUND: " + old[:70])
open(p, 'w').write(t.replace(old, new, 1))
PY
  ( cd "$HERE" && make -s simv >"/tmp/mut_$name.build.log" 2>&1 \
      && ./simv +ntb_random_seed=1 +ncycles=$NCYC -l "/tmp/mut_$name.sim.log" >/dev/null 2>&1 )
  if [ ! -f "/tmp/mut_$name.sim.log" ]; then
    echo "  [$name] ★建不起来★ 见 /tmp/mut_$name.build.log"; restore; return 2
  fi
  grep -E '^  (A |B )|^TEST' "/tmp/mut_$name.sim.log" | sed "s/^/  [$name] /"
  if grep -q 'TEST FAILED' "/tmp/mut_$name.sim.log"; then
    echo "  [$name] => 判别力 OK（UT 报出来了）"
  else
    echo "  [$name] ★★ 判别力缺失：注入了真 bug 但 UT 仍然 PASSED ★★"
  fi
  restore
}

echo "=== MA-1: 声明为 clean 的常量位被改掉（ssid 0 -> 1）==="
run_one MA-1 "assign rename_uop[0].ssid = 5'h0;||=>||assign rename_uop[0].ssid = 5'h1;"

echo "=== MA-2: 破坏 srcState 逐 IQ 掩码（该折 0 的不折）==="
run_one MA-2 "if (!SRCSTATE_LIVE[q / 2][2]) iq_uop[q].srcState_2 = 1'b0;||=>||if (1'b0) iq_uop[q].srcState_2 = 1'b0;"

echo "=== MA-3: 一个 debugInfo 常量位被改掉（64'h0 -> 64'h1）==="
run_one MA-3 "assign rename_uop[3].debugInfo_issueTime = 64'h0;||=>||assign rename_uop[3].debugInfo_issueTime = 64'h1;"

restore
NOW_SHA=$(sha256sum "$SRC" | cut -c1-64)
echo
if [ "$NOW_SHA" = "$ORIG_SHA" ]; then echo "还原核对 OK: sha256 未变 ($NOW_SHA)";
else echo "★还原失败★ $ORIG_SHA -> $NOW_SHA ，请从 $BAK 手工恢复"; exit 1; fi
echo "判据：每个 MA-* 都必须 TEST FAILED 且 'A 清单外失配' > 0。"
