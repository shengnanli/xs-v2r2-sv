#!/bin/bash
# =============================================================================
# golden 对 golden 的**自比基线** —— 先量地板在哪，再谈重写件过没过
#
# 为什么必须有它（2026-09-20 实测，这一跑改变了结论）：
#   TlbStorageWrapper_2 的 UT 在 seed=7 + `+vcs+initreg+random` 下报 errors=1
#   （vec 0，io_r_resp_1_bits_ppn_0，g=ffffffffe i=fffffffff）。看起来像重写 bug。
#   把 **golden 的一份副本改名成 _xs** 当作"实现"再跑一次 —— 两侧逐字节相同的
#   golden —— ★同一个 seed、同一拍、同一个端口，照样 errors=1★。
#   所以那不是重写件的问题：它量的不是设计，是随机初值。
#
# 根因（观测出来的，不是猜的）：golden 里 hitVecReg_<port>_<way> 是
#   `RegEnable(hitVec, io_r_req_<port>_valid)` —— **该端口收到第一个 valid 请求之前
#   一直保持上电随机值**，而 resp.hit / resp.ppn 都是这 48 位的或树。
#   定向段只驱动端口 0，于是端口 1 在第一拍比的是两边各自的随机数。
#   修法是 tb 的 dir_warm_ports()：每个读端口都先发一拍 valid 请求。
#   （前两个猜法——"多等几拍"和"把 48 路全填满"——实测都**没用**，
#     记在这里是因为"看起来合理但没复现"本身就是结论的一部分。）
#
# 本脚本的用法：任何时候 UT 报 errors>0，先跑它。
#   - 自比也报同样的错 ⇒ 是 tb/激励问题或 golden 自身的不确定性，不是重写件
#   - 自比干净而重写件报错 ⇒ 是重写件的问题
#
# 用法: [CYCLES=5000] bash verif/ut/TlbStorageWrapper/selfcmp.sh [变体号 ...]
#       默认跑 2 3，seed 1/7/42/99/123 × initreg 0/random
# 退出码 0 = 自比全零（地板就是 0，重写件必须也做到 0）
# =============================================================================
set -u
HERE=$(cd "$(dirname "$0")" && pwd)
G=${GOLDEN_RTL:-/home/eda/xs-env/G1-canonical/golden-rtl}
CYCLES=${CYCLES:-5000}
VARS=${@:-2 3}
W=${TMPDIR:-/tmp}/tlbsw23-selfcmp-$$-$RANDOM
mkdir -p "$W" || exit 2
rc=0
for V in $VARS; do
  d=$W/v$V; mkdir -p "$d"; cd "$d" || exit 2
  # golden 副本改名成 _xs：tb 的"实现侧"喂的是**同一份 golden 逻辑**
  sed -E "s/\bTlbStorageWrapper_$V\b/TlbStorageWrapper_${V}_xs/g; s/\bTLBFA_$V\b/TLBFA_${V}_xs/g" \
      "$G/TlbStorageWrapper_$V.sv" > w_xs.sv
  sed -E "s/\bTLBFA_$V\b/TLBFA_${V}_xs/g" "$G/TLBFA_$V.sv" > f_xs.sv
  vcs -full64 -sverilog -timescale=1ns/1ps -lca +define+SYNTHESIS +vcs+initreg+random \
      "$G/TLBFA_$V.sv" "$G/TlbStorageWrapper_$V.sv" f_xs.sv w_xs.sv \
      "$HERE/tb_$V.sv" -top tb -o simself > compile.log 2>&1
  if [ ! -x ./simself ]; then echo "[v$V] ★自比编译失败（见 $d/compile.log）"; rc=1; continue; fi
  for seed in 1 7 42 99 123; do
    for ir in 0 random; do
      ./simself +ntb_random_seed=$seed +vcs+initreg+$ir +ncycles=$CYCLES -l s_${seed}_${ir}.log >/dev/null 2>&1
      e=$(grep -oP '^checks=\d+ errors=\K\d+' s_${seed}_${ir}.log)
      if [ "${e:-X}" != "0" ]; then
        echo "[v$V seed=$seed initreg=$ir] ★自比 errors=${e:-无输出}  $(grep -m1 '^vec ' s_${seed}_${ir}.log)"
        rc=1
      fi
    done
  done
  [ $rc -eq 0 ] && echo "[v$V] 自比基线 errors=0（5 seed × 2 initreg × $CYCLES 拍）"
done
echo "（工作目录 $W）"
exit $rc
