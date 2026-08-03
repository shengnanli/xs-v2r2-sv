#!/usr/bin/env bash
# Rob SoA co-sim: packed-ref (xs_Rob_core_packed_ref) vs SoA (xs_Rob_core), 94 outputs/cycle.
# Usage: run_cosim.sh <seed> [label]
set -u
SEED="${1:-1}"; LABEL="${2:-base}"
RTL=/tmp/rob-soa-integ/rtl/backend
TBDIR=/tmp/rob-soa-integ/verif/ut/Rob
EV=/tmp/rob-soa-integ-evidence/cosim_${LABEL}_seed${SEED}
rm -rf "$EV"; mkdir -p "$EV"; cd "$EV"
export VCS_ARCH_OVERRIDE=linux
SRCS="$RTL/rob_pkg.sv $RTL/Rob.sv $RTL/Rob_packed_ref.sv $RTL/rob_lsq_deep_outputs.sv $TBDIR/tb_cosim.sv"
vcs -full64 -sverilog -timescale=1ns/1ps +define+SYNTHESIS \
    -top tb $SRCS -o simv_cosim -l compile.log \
    > vcs_stdout.log 2>&1
RC=$?
if [ $RC -ne 0 ] || [ ! -x ./simv_cosim ]; then
  echo "COSIM_COMPILE_FAIL rc=$RC"; tail -30 compile.log; exit 2
fi
./simv_cosim +ntb_random_seed=$SEED +seed=$SEED -l run.log > run_stdout.log 2>&1
grep -E "checks=|errors=|TEST PASSED|TEST FAILED|MISMATCH" run.log run_stdout.log 2>/dev/null | tail -20
CHK=$(grep -oE "checks=[0-9]+" run.log run_stdout.log 2>/dev/null | tail -1)
ERR=$(grep -oE "errors=[0-9]+" run.log run_stdout.log 2>/dev/null | tail -1)
echo "COSIM_RESULT label=$LABEL seed=$SEED $CHK $ERR"
