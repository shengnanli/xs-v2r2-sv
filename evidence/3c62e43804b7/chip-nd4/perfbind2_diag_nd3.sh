#!/bin/bash
# 整芯片启动失败二分：TAG=<名> EXCLUDE="<rtl 相对路径 ...>"  在分离 worktree 里删掉这些重写件（回落 golden）→ 清单 → 重绑 SimTop → 编译 → 跑 20k 拍
set -euo pipefail
TAG=${TAG:?}; EXCLUDE=${EXCLUDE:-}
REPO=/home/eda/xs-env/xs-v2-sv; G=/home/eda/xs-env/G1-canonical/golden-rtl
OLD=/home/eda/xs-env/sim-work-perfbind/impl
S=/tmp/claude-1000/-home-eda-xs-env-XiangShan/6824a231-879a-49e3-b98d-f29f5afc381c/scratchpad
NEW=/home/eda/xs-env/sim-work-perfbind2/$TAG; RTR=/home/eda/xs-env/XiangShan/ready-to-run
WT=$S/diag-wt-$TAG
trap 'git -C $REPO worktree remove --force $WT >/dev/null 2>&1 || true' EXIT
echo "DIAG[$TAG] $(date) commit: $COMMIT exclude: $EXCLUDE"
rm -rf $NEW; mkdir -p $NEW/build/rtl $NEW/run/cm20k
git -C $REPO worktree remove --force $WT >/dev/null 2>&1 || true
git -C $REPO worktree add --detach $WT ${COMMIT:?} >/dev/null 2>&1
for f in $EXCLUDE; do rm -f $WT/$f && echo "  excluded $f"; done
cp -a $OLD/build/generated-src $NEW/build/; cp -a $OLD/build/{chisel_db.cpp,chisel_db.h,constantin.cpp,constantin.hpp,constantin.txt,perfCCT.cpp,perfCCT.h,vc_hdrs.h} $NEW/build/
cd $WT; export XSSV_HOME=$WT
python3 scripts/full_elab_filelist.py --golden $G --rtl $WT/rtl --out $NEW/files_simtop.f --with-difftest --report > $NEW/filelist.log 2>&1; grep -E '顶掉|写出' $NEW/filelist.log
grep -v '/golden-rtl/SimTop.sv$' $NEW/files_simtop.f > $NEW/files_impl_nosimtop.f
python3 scripts/perf_rebind.py --golden $G --filelist $NEW/files_simtop.f --emit-simtop $NEW/build/rtl/SimTop.sv > $NEW/rebind.log 2>&1; grep -E '重绑 SimTop|复核' $NEW/rebind.log | cut -c1-120
sed -e "s|/home/eda/xs-env/sim-work-perfbind/impl|$NEW|g" -e "s/ -j200 / -j${JOBS:-48} /" $S/old_vcs_cmd.txt > $NEW/vcs_cmd.sh
cd $NEW; export VCS_ARCH_OVERRIDE=linux
echo "BUILD[$TAG] start $(date)"; bash $NEW/vcs_cmd.sh > $NEW/build.log 2>&1 || { echo "BUILD[$TAG] FAIL"; grep -m5 -E 'Error-\[' build.log; exit 4; }
echo "BUILD[$TAG] ok $(date)"
cd $NEW/run/cm20k; ../../build/simv +diff=$RTR/riscv64-nemu-interpreter-so +workload=$RTR/coremark-2-iteration.bin +max-cycles=20000 +b=0 +e=1000000 > sim.log 2> assert.log || true
echo "RESULT[$TAG]: $(grep -oE 'instrCnt = [0-9,]+|does not commit|EXCEEDED MAX CYCLE|GOOD TRAP|HIT BAD' sim.log | head -3 | tr '\n' ' ')  assert.log=$( [ -s assert.log ] && wc -l < assert.log || echo 无 )  $(date)"
