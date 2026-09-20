#!/bin/bash
# =============================================================================
# initreg 有效性判据 —— 证明 `+vcs+initreg` 真的改变了 TlbStorageWrapper_2 的状态
#
# 背景（本仓已知坑）：★非打包数组的混合驱动会让 VCS 静默关掉 +vcs+initreg★。
# 一旦发生，"两轮 initreg 都绿"是假覆盖：第二轮根本没换初值。重写件里正好有三个
# 非打包数组（acc_valid[] / acc_bits[] / access[]），所以必须当场量。
#
# 三跑（tb_initreg_probe.sv：复位全程不拉高，在任何时钟沿之前打内部寄存器）：
#   A  +vcs+initreg+0                      期望 全 0
#   B  +vcs+initreg+random seed=1          期望 ≠ A
#   C  +vcs+initreg+random seed=7          期望 ≠ A 且 ≠ B（否则"random"是常数）
#
# 判据（三条都要成立，任何一条不成立即 rc=1）：
#   1) A 全 0
#   2) B ≠ A            —— initreg 确实进到了被测状态
#   3) C ≠ B            —— 取值真的随 seed 变，不是固定图样
#
# 用法: bash verif/ut/TlbStorageWrapper/initreg_probe_check.sh
# =============================================================================
set -u
HERE=$(cd "$(dirname "$0")" && pwd)
R=$HERE/../../../rtl/memblock
W=${TMPDIR:-/tmp}/tlbsw23-initreg-$$-$RANDOM
mkdir -p "$W" || exit 2
cd "$W" || exit 2

vcs -full64 -sverilog -timescale=1ns/1ps -lca +define+SYNTHESIS +vcs+initreg+random \
    "$R/memblock_common_pkg.sv" "$R/xs_TlbStorageWrapper_core.sv" \
    "$R/xs_TLBFA_core.sv" "$R/TLBFA_2.sv" "$R/TlbStorageWrapper_2.sv" \
    "$HERE/tb_initreg_probe.sv" -top tb -o simp > compile.log 2>&1
[ -x ./simp ] || { echo "★探针编译失败（见 $W/compile.log）"; exit 2; }

run() { ./simp "$@" -l "$1.log" 2>/dev/null | grep '^PROBE' | tr '\n' ' '; }
A=$(./simp +vcs+initreg+0                        2>/dev/null | grep '^PROBE' | tr '\n' ' ')
B=$(./simp +vcs+initreg+random +ntb_random_seed=1 2>/dev/null | grep '^PROBE' | tr '\n' ' ')
C=$(./simp +vcs+initreg+random +ntb_random_seed=7 2>/dev/null | grep '^PROBE' | tr '\n' ' ')
echo "A(initreg+0)          : $A"
echo "B(initreg+random s=1) : $B"
echo "C(initreg+random s=7) : $C"

rc=0
[ -n "$A" ] && [ -n "$B" ] && [ -n "$C" ] || { echo "★探针没打出 PROBE 行"; exit 2; }
case "$A" in *[1-9a-fA-FxXzZ]*) ;; esac
if echo "$A" | grep -qE '=[0]+ '; then echo "  ok  1) +vcs+initreg+0 下内部寄存器全 0"
else echo "  FAIL 1) +vcs+initreg+0 下不是全 0：$A"; rc=1; fi
if [ "$B" != "$A" ]; then echo "  ok  2) random ≠ 0 —— initreg 确实改变了待测状态"
else echo "  FAIL 2) random 与 0 相同 —— ★initreg 没生效，两轮 UT 是假覆盖★"; rc=1; fi
if [ "$C" != "$B" ]; then echo "  ok  3) 两个 seed 的 random 值不同 —— 不是固定图样"
else echo "  FAIL 3) 换 seed 值不变 —— random 实际是常数"; rc=1; fi
echo "（工作目录 $W）"
exit $rc
