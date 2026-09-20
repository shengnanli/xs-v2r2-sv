#!/usr/bin/env bash
# Rob UT 验收矩阵：3 seed x 2 轮 initreg。每个 seed 内部**串行**（两轮共用
# sim_<seed>.log，同名并发会互相覆盖——本轮已经踩过一次），seed 之间并行。
set -u
s=$1
for ir in 0 random; do
  if make run SEED=$s INITREG=+vcs+initreg+$ir > run_s${s}_ir${ir}.log 2>&1; then
    echo "SEED=$s INITREG=$ir RESULT=PASS $(grep -o 'checks=[0-9]* errors=[0-9]*' run_s${s}_ir${ir}.log | tail -1)"
  else
    echo "SEED=$s INITREG=$ir RESULT=FAIL $(grep -o 'checks=[0-9]* errors=[0-9]*' run_s${s}_ir${ir}.log | tail -1)"
  fi
done
echo "SEED=$s DONE"
