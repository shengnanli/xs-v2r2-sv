#!/usr/bin/env bash
# run_cputest.sh —— 把 nexus-am cputest 的 33 个小体系结构测试在 golden / impl 两侧
# 各跑一遍(difftest + NEMU 锁步)，逐项对比 instrCnt / cycleCnt / TRAP 结果。
#
# 为什么用它而不是 coremark：整芯片 difftest 仿真实测 ~75 cycle/s(difftest 的 vcs.mk
# 固定 -debug_access+all)，coremark 要千万级周期跑不完；cputest 每个 ~5k 周期、
# 单次 ~33s，33 个并行跑几分钟就有结论，而且是**体系结构**覆盖而非单点。
#
# 前置：先 build 出两侧 simv(verif/sim/run_fullchip.sh build golden|impl)，
#       并编好负载：
#   cd $AM_HOME/tests/cputest && \
#   make ARCH=riscv64-xs CROSS_COMPILE=riscv64-none-linux-gnu-
#   (工具链 XiangShan/riscstar-toolchain-*/bin；nexus-am 的 isa/riscv64.mk 默认
#    CROSS_COMPILE=riscv64-unknown-linux-gnu-，本机只有 -none-，必须显式覆盖)
#
# 用法: verif/sim/run_cputest.sh [并行度]
set -uo pipefail
SIMW=${SIMW:-/home/eda/xs-env/sim-work}
WL=${WL:-$SIMW/workloads}
REF=${REF:-/home/eda/xs-env/XiangShan/ready-to-run/riscv64-nemu-interpreter-so}
JOBS=${1:-8}
export VCS_ARCH_OVERRIDE=linux

run_one() {  # $1=side $2=binpath
  local side=$1 b=$2 name; name=$(basename "$b" -riscv64-xs.bin)
  local d=$SIMW/$side/run/cputest; mkdir -p "$d"
  ( cd "$d" && timeout 900 "$SIMW/$side/build/simv" "+workload=$b" "+diff=$REF" \
      +ram_size=8589934592 -suppress=ASLR_DETECTED_INFO > "$name.log" 2>&1 )
}
export -f run_one; export SIMW REF

for side in golden impl; do
  for b in "$WL"/*.bin; do echo "$side $b"; done
done | xargs -P "$JOBS" -n2 bash -c 'run_one "$0" "$1"'

# --- 汇总 ---
printf '%-18s | %-34s | %-34s | %s\n' TEST GOLDEN IMPL VERDICT
printf '%s\n' "-------------------+------------------------------------+------------------------------------+--------"
pass=0; fail=0
for b in "$WL"/*.bin; do
  n=$(basename "$b" -riscv64-xs.bin)
  sum() { # trap + instrCnt/cycleCnt
    local f=$1
    local t; t=$(grep -oE "HIT (GOOD|BAD) TRAP" "$f" | head -1)
    local c; c=$(grep -oE "instrCnt = [0-9,]+, cycleCnt = [0-9,]+" "$f" | head -1)
    local m; m=$(grep -cE "different at pc|DIFFTEST FAILED" "$f")
    echo "${t:-NO-TRAP} ${c:-no-count} mism=$m"
  }
  g=$(sum "$SIMW/golden/run/cputest/$n.log"); i=$(sum "$SIMW/impl/run/cputest/$n.log")
  if [ "$g" = "$i" ] && [ "${g%% *}" = "HIT" ]; then v=SAME; pass=$((pass+1)); else v=DIFF; fail=$((fail+1)); fi
  printf '%-18s | %-34s | %-34s | %s\n' "$n" "${g:0:34}" "${i:0:34}" "$v"
done
echo "SAME=$pass DIFF=$fail"
