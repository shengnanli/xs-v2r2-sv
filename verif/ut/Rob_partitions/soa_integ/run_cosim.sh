#!/usr/bin/env bash
# Rob SoA integrator co-sim gate: compile once, run seeds 1/7/42.
# Usage: run_cosim.sh <label>
set -u
LABEL="${1:-base}"
RTL=/tmp/rob-soa-integ2/rtl/backend
TBDIR=/tmp/rob-soa-integ2/verif/ut/Rob
EV=/tmp/rob-soa-integ2-evidence/cosim_${LABEL}
rm -rf "$EV"; mkdir -p "$EV"; cd "$EV"
export VCS_ARCH_OVERRIDE=linux
SRCS="$RTL/rob_pkg.sv $RTL/Rob.sv $RTL/Rob_packed_ref.sv $RTL/rob_lsq_deep_outputs.sv $TBDIR/tb_cosim.sv"
vcs -full64 -sverilog -timescale=1ns/1ps +define+SYNTHESIS +vcs+initreg+random \
    -top tb $SRCS -o simv_cosim -l compile.log \
    > vcs_stdout.log 2>&1
RC=$?
if [ $RC -ne 0 ] || [ ! -x ./simv_cosim ]; then
  echo "COSIM_COMPILE_FAIL rc=$RC"; tail -30 compile.log; exit 2
fi
FAIL=0
for SEED in 1 7 42; do
  ./simv_cosim +ntb_random_seed=$SEED +vcs+initreg+0 -l run_seed${SEED}.log \
      > run_stdout_seed${SEED}.log 2>&1
  CHK=$(grep -oE "checks=[0-9]+" run_seed${SEED}.log | tail -1)
  ERR=$(grep -oE "errors=[0-9]+" run_seed${SEED}.log | tail -1)
  PASS=$(grep -cE "TEST PASSED" run_seed${SEED}.log)
  echo "COSIM_RESULT label=$LABEL seed=$SEED $CHK $ERR passed=$PASS"
  [ "$ERR" = "errors=0" ] && [ "$PASS" -ge 1 ] || FAIL=1
done
echo "COSIM_GATE label=$LABEL fail=$FAIL"
exit $FAIL
