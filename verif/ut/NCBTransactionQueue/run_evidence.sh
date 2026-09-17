#!/bin/bash
# run_evidence.sh —— 本目标 UT 的可复跑证据脚本（3 seed × 2 轮 initreg × 200k 拍）。
#
# ★两处都要给 +vcs+initreg★：编译期 `+vcs+initreg+random`（打开机制，在 Makefile 里）
# 与运行期 `+vcs+initreg+<0|random>`（选取值，这里下发）。只给运行期 VCS 会静默忽略。
# 日志逐轮单独留档（ut_common.mk 的默认名 sim_<seed>.log 会被下一轮覆盖）。
set -e
cd "$(dirname "$0")"
export VCS_ARCH_OVERRIDE=linux
make compile >/dev/null
for ir in random 0; do
  for s in 1 7 42; do
    ./simv +ntb_random_seed=$s +ncycles=200000 +vcs+initreg+$ir -l evidence_ir${ir}_seed${s}.log >/dev/null
    printf '%-24s %s\n' "initreg=$ir seed=$s" \
      "$(grep -E 'checks=|TEST ' evidence_ir${ir}_seed${s}.log | tr '\n' ' ')"
  done
done
